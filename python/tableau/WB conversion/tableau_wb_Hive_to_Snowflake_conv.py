#!/usr/bin/python
#
# ============================================== Tableau Workbook Migrtion Generator =========================================
# 
# Migrate Tableau workbook file (tds included (twbx)) into Snowflake version
#
# Version : 2.3v
# Create by: Igal Emona
#
#
#

import os
import zipfile
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




## -------------- Migration Variables and Paramters:

serverSnowflake = { 'name' : 'snowflake.xxxxxxxxxxxxxx',
                    'server' : 'xxxxxxxx.us-east-1.snowflakecomputing.com',
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
              'warehouse' : 'XXXXXXXXXXXX'}

relationSNF = {'connection' : namedConnectionSNF['name'],
                'schemaNameSRC' : '[XXXXXX]',
                'schemaNameTRG' : '[XXXXXXXXXX]'
                }

xmlHeader='''<?xml version='1.0' encoding='utf-8' ?>

<!-- build 20194.20.0125.0835                               -->\n'''

allTables=[]

ACCOUNT_NAME = 'xxxxxxx.us-east-1'
USER_NAME = 'XXXXXXXXX'
DB_NAME = 'XXXXX'
WAREHOUSE = 'XXXXXXXXXXX'
SCHEMA = 'XXXXX'
ROLE_NAME = 'XXXXX'


packaged_workbook_path = os.path.abspath(xmlFilename)
file_ext = f'.{packaged_workbook_path.split(".")[-1]}'
extract_dir = os.path.abspath(f'snowflake_migration_{os.path.basename(packaged_workbook_path).strip(file_ext)}/')
packaged_workbook_path, extract_dir

#### First, unpack your packaged (*.tbwx) workbook by renaming and unzipping the file:


def unpack(packaged_workbook_path, extract_dir):
    
    packaged_workbook_path = os.path.abspath(packaged_workbook_path)
    file_ext = f'.{packaged_workbook_path.split(".")[-1]}'
    zip_file_path = packaged_workbook_path.replace(file_ext, '.zip')
    
    if not os.path.exists(packaged_workbook_path):
        raise Exception(f'File {packaged_workbook_path} does not exist')
    
    os.rename(packaged_workbook_path, zip_file_path)
    print(f'Renamed {packaged_workbook_path} to {zip_file_path}')
    
    with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)
    
    print(f'Unzipped {zip_file_path} to {extract_dir}')
    
    file_ext_wb = file_ext.strip('x')
    
    file_path_wb = packaged_workbook_path.replace(file_ext, file_ext_wb)
    file_path_wb = os.path.join(extract_dir, os.path.basename(file_path_wb))
    
    return file_path_wb


#### Then we parse the xml tree of the unpacked workbook to find the named connections and relation section and substitute the relevant Redshift sections with our Snowflake equivalents:


def migrate_to_snowflake(workbook_book_path):
    
    tree = ET.parse(workbook_book_path)
    root = tree.getroot()
    for ds in root.findall('.//datasource'):
        #         print([(k,v) for k,v in ds.items()])
        if ds.get('hasconnection') or ds.get('hasconnection') is None:
            print('Child: ', [c.tag for c in ds.getchildren()], '\n')
            # for nm in ds.findall('.//named-connection'):
        
        
    for ds in root.findall('.//datasource'):
    
        if ds.get('hasconnection') or ds.get('hasconnection') is None:
            
            for nm in ds.findall('.//named-connection'):
    
                print(nm.tag, nm.get('name'), nm.get('caption'))
                nm.set('caption', f'{ACCOUNT_NAME}.snowflakecomputing.com')
                nm.set('name', nm.get('name').replace('redshift', 'snowflake'))
                print('>>', nm.tag, nm.get('name'), nm.get('caption'))

                for cn in nm.getchildren():
                    print('\t', cn.tag, cn.get('class'), cn.get('server'))
                    cn.set('class', 'snowflake')
                    cn.set('schema', f'{SCHEMA}')
                    cn.set('dbname', f'{DB_NAME}')
                    cn.set('server', f'{ACCOUNT_NAME}.snowflakecomputing.com')
                    cn.set('service', f'{ROLE_NAME}')
                    cn.set('username', f'{USER_NAME}')
                    cn.set('warehouse', f'{WAREHOUSE}')
                    cn.set('port', '')
                    print('\t>>', cn.tag, cn.get('class'), cn.get('server'))
                    print('\n')

            for rel in ds.iter('relation'):
                if rel.get('connection') is not None:
                    print(rel.tag, rel.get('connection'))
                    rel.set('connection', rel.get('connection').replace('redshift', 'snowflake'))
                    print('>>', rel.tag, rel.get('connection'))
                    print('\n')
    
    for ds in root.findall('.//'):
        ### ---------------------------------------------- Named-connection:
        for named_connection in ds.findall('named-connection'):
            named_connection.attrib = namedConnectionSNF

        ### ---------------------------------------------- Connection:
        # for named_conn_connection in ds.findall('connection'):
        #     if named_conn_connection.attrib['schema'] == 'Extract': ## Exclude Extract Type from conversion
        #             named_conn_connection.attrib['dbname'] = ""     
        #     else:
        #         named_conn_connection.attrib = namedConnection_connectionSNF

        ### ---------------------------------------------- Expressions:
        for exp in ds.findall('expression'): 
            for att in exp.attrib:
                if exp.attrib[att].count('.') > 0:
                    expTable = exp.attrib[att].split('.')
                    expLength = len(expTable) - 1
                    expColumn = expTable[expLength].upper()
                    expTableName = expTable[0].split(' ')[0]
                    if expTableName[-1] != ']':
                        expTableName+=']'
                    expTable = [expTableName, expColumn]
                    exp.attrib[att] = '.'.join(expTable)   

        ### ---------------------------------------------- Relations & Repalcing entities by user:    
        for rel in ds.findall('relation'):
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
                                newTableNameSNF = input('       - Insert new table/view name >> ')
                                relTable[1] = "[" + newTableNameSNF.upper() + "]"
                            else:
                                relTable[1] = relTable[1].upper()
                                allTables.append('.'.join(relTable))
                                rel.attrib['table'] = '.'.join(relTable)                        
                        relName = rel.attrib['name'].split(' ')
                        rel.attrib['name'] = relName[0] 
                        relTable[1] = relTable[1].upper()
                        rel.attrib['table'] = '.'.join(relTable)     

        for col in ds.findall('cols/'):
            if col.tag == 'map':
                for att in col.attrib:
                    if col.attrib[att].count('.') > 0:
                        colTable = col.attrib[att].split('.')
                        colLength = len(colTable) - 1
                        colColumn = colTable[colLength].upper()
                        colTableName = colTable[0].split(' ')[0]
                        if colTableName[-1] != ']':
                            colTableName+=']'
                        colTable = [colTableName, colColumn]
                        col.attrib[att] = '.'.join(colTable)

    return tree


### Lastly, save the updated XML to a new file:

def save_migrated_workbook(tree, file_path_wb):
    file_ext_wb = f'.{file_path_wb.split(".")[-1]}'
    new_path = file_path_wb.replace(file_ext_wb, f'_converted{file_ext_wb}')
    if not os.path.exists(new_path):
        tree.write(new_path)
        print(f'Migrated {file_path_wb} to {new_path}')
    else:
        print(f'{new_path} already exists!')

if xmlFilename.split('.')[1].lower() == 'twbx':
    file_path_wb = unpack(packaged_workbook_path, extract_dir)
else:
    file_path_wb = xmlPath + xmlFilename     

tree = migrate_to_snowflake(file_path_wb)
save_migrated_workbook(tree, file_path_wb)
