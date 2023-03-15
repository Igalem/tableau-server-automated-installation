#!/usr/bin/python
#
# ---- Tableau Data Source Migrtion Generator ----
# 
# Convert tds file into Snowflake support tds
#
# Version : 2.3v
# Created by: Igal Emona
# 
#  - Exlude extract action from conversion of SNF connection (2021-07-12)
#  - Set init default value ("") for DS extraction path (2021-07-13)
#  - Prevent renaming/replacing <map> / <relation> "name" tables/aliases (2021-08-08)

import os
import xml.etree.ElementTree as ET

print('\033c')
print('\n        ***** Tableau Data Source Migrtion to Snowflake :: Generator ***** \n')
xmlPath = input('--| Please enter TDS file path: ---> ') 
xmlFilename = input('\n----| TDS filname ---> ')

if len(xmlPath) > 0:
	xmlPath
else:
	xmlPath = os.path.abspath(os.getcwd()) + '/'

try:
	listDirectory = os.listdir(xmlPath)
except:
	print('\n- Error: Datasource filename or path not exists (!) ')
	print('Migration aboarted.  \n')
	exit()
else:
	pass

if xmlFilename not in listDirectory:
	print('\n- Error: Datasource filename or path not exists (!) ')
	print('Migration aboarted.  \n')
	exit()



### -------------- Migration Variables and Paramters:

serverSnowflake = { 'name' : 'snowflake.xxxxxxxxxxxxxxxxxxxxx',
					'server' : 'xxxxxx.us-east-1.snowflakecomputing.com',
					'schema' : 'XXX_XXX_XXX'
					}


namedConnectionSNF = {'caption' : serverSnowflake['server'],
					'name' : serverSnowflake['name']
					}

namedConnection_connectionSNF = {'authentication' : 'Username Password',
			  'class' : 'snowflake',
			  'dbname' : 'XXXXX',
			  'odbc-connect-string-extras' : '',
			  'one-time-sql' : '',
			  'schema' : serverSnowflake['schema'],
			  'server' : serverSnowflake['server'],
			  'service' : '',
			  'username' : 'XXXXXXX',
			  'warehouse' : 'XXXXXXX'}

relationSNF = {'connection' : namedConnectionSNF['name'],
				'schemaNameSRC' : '[XXXXXX]',
				'schemaNameTRG' : '[XXXXXXXXX]'
				}

xmlHeader='''<?xml version='1.0' encoding='utf-8' ?>

<!-- build 20194.20.0125.0835                               -->\n'''

xmlPrefixSNF = xmlFilename.split('.')[0]
xmlSufixSNF = xmlFilename.split('.')[1]
xmlFilenameSNF = xmlPrefixSNF + ' SNF.' + xmlSufixSNF
xmlTemp = xmlPrefixSNF + '_tmp.xml'

allTables=[]

#### --------------------- Convert SnowFlake DataSource ---------------------------

### Load XML Tree file into root:
xmlTree=ET.parse(xmlPath + xmlFilename)
root=xmlTree.getroot()

## Set mapping parameters (zip(t,c))
mapColumns = []
mapTables = []


## ==== Finadll
for datasource in root.findall('.//'):
	for named_connection in datasource.findall('named-connection'):
		named_connection.attrib = namedConnectionSNF

	for named_conn_connection in datasource.findall('connection'):
		if named_conn_connection.attrib['schema'] == 'Extract': ## Exclude Extract Type from conversion
				named_conn_connection.attrib['dbname'] = ""		
		else:
			named_conn_connection.attrib = namedConnection_connectionSNF

	# for child in datasource.findall('named-connection/connection'):
	# 	for subchild in child:
	# 		if subchild.tag != 'connection':
	# 			child.remove(subchild) ## remove subChild's childs

	for rel in datasource.findall('relation'):
		if 'connection' in rel.attrib:
			for att in rel.attrib:
				if att in relationSNF.keys():
					rel.attrib[att] = relationSNF[att]
				elif att == 'table' and rel.attrib[att].count('.') > 0:
					relTable = rel.attrib[att].split('.')
					if relTable[0].lower() == '[dwh_prod]':
						relTable[0] = relationSNF['schemaNameSRC']
						relTable[1] = relTable[1].upper()
						allTables.append('.'.join(relTable))
					else:
						replaceTableNameSNF = input('\nReplace table/view name:' + str('.'.join(relTable)).upper() + ' (y/n) ? >> ')
						relTable[0] = relationSNF['schemaNameTRG']
						if replaceTableNameSNF.lower() == 'y':
							newTableNameSNF = input('		- Insert new table/view name >> ')
							relTable[1] = "[" + newTableNameSNF.upper() + "]"

						else:
							relTable[1] = relTable[1].upper()
							allTables.append('.'.join(relTable))
							rel.attrib['table'] = '.'.join(relTable)
						
						
					#relName = rel.attrib['name'].split(' ')
					#rel.attrib['name'] = relName[0]	

					relTable[1] = relTable[1].upper()
					rel.attrib['table'] = '.'.join(relTable)


	for exp in datasource.findall('expression'):
		for att in exp.attrib:
			if exp.attrib[att].count('.') > 0:
				#print(exp.attrib[att])
				expPath = exp.attrib[att]
				#print(expPath + '---------')
				pointIndex = 0
				for i,e in enumerate(expPath):
					if e == '.':
						pointIndex = i + 1
				expColumnUpper = expPath[pointIndex : len(expPath)].upper()
				exp.attrib[att] = expPath[0 : pointIndex] + expColumnUpper


	for col in datasource.findall('cols/'):
		if col.tag == 'map':
			for att in col.attrib:
				if col.attrib[att].count('.') > 0:
					colPath = col.attrib[att]
					pointIndex = 0
					for i,e in enumerate(colPath):
						if e == '.':
							pointIndex = i + 1
					colColumnUpper = colPath[pointIndex : len(colPath)].upper()
					col.attrib[att] = colPath[0 : pointIndex] + colColumnUpper				



# 	for meta in datasource.findall('metadata-records/metadata-record'):
# 		if meta.attrib['class'] == 'column':
# 			tagReset = 0
# 			for col in datasource.findall('metadata-records/metadata-record/remote-name'):
# 				mapColumns.append(col.text)
# 			for tab in datasource.findall('metadata-records/metadata-record/parent-name'):
# 				mapTables.append(tab.text)

# 			mapTableList = []
# 			for t,c in zip(mapTables, mapColumns):
# 				if t.lower() != '[extract]':
# 					mapTableList.append(str(t) + '.' + str(c))

# 			mapDistinctTables = set(mapTableList) ## --- Distinct tables
# 			mapTextList = []

# 			for tabCol in mapDistinctTables:
# 				tab = tabCol.split('.')
# 				t = tab[0]
# 				c = tab[1]
# 				mapKey = "[" + str(c) + "]"
# 				mapValue = t + '.' + mapKey.upper()
# 				mapText = ' key=' + mapKey + ' value=' + mapValue
# 				mapTextList.append(mapText)
				
				
				
# colTag = ET.Element("col") ## ---- Create "cols"
# #colTag.text = '\n		'	

# for mapLine in mapTextList:
# 	colTag.text = '\n		'
# 	col_map = ET.SubElement(colTag, "map")
# 	col_map.text = mapLine
# 	root.insert(2, colTag)            
	


####  ===== Print out Migrated XML into temporarly XML file

xmlTree.write(xmlPath + xmlTemp,encoding = 'utf-8')

# Reading data from file1
xmlDataFile = open(xmlPath + xmlTemp, 'r') 

xmlFile = open(xmlPath + xmlFilenameSNF, 'w')
xmlFile.write(xmlHeader)

#### Remove unneccessary nameSpaces:
for line in xmlDataFile:
	line = line.replace('ns0' , 'user').\
				replace('`', '').\
				replace('hadoophive', 'snowflake').\
				replace('&gt;&gt;', '>').\
				replace('&lt;&lt;', '<').\
				replace('int_bi_dwh' , serverSnowflake['schema'])
#				replace('</map>', '/> \n	')

	
	xmlFile.write(line)

	
os.remove(xmlPath+xmlTemp)	

print('\nFollowing Data Source included tables/view: \n')
#print(allTables)
for table in allTables:
	print(str(table).replace('[','').replace(']',''))

print('\n---------------------------------' + '-' * (len(xmlFilename)+5))
print('Migration completed!')
print('New TDS migrated file created as: ' + xmlFilenameSNF )
print('---------------------------------' + '-' * (len(xmlFilename)+5) + '\n')

xmlDataFile.close()
xmlFile.close()


