import requests
import xmltodict,json

url='http://0.0.0.0/admin/systeminfo.xml'
project='tableau'
tag='tableau_server'

# the following try/except block will make the custom check compatible with any Agent version
try:
    # first, try to import the base class from new versions of the Agent...
    from datadog_checks.base import AgentCheck
except ImportError:
    # ...if the above failed, the check is running in Agent version < 6.6.0
    from checks import AgentCheck

# content of the special variable __version__ will be shown in the Agent status page
__version__ = "1.0.0"

class TsmCheck(AgentCheck):
	def check(self, instance):
		data=requests.get(url)
		obj=data.content
		xmlobj=xmltodict.parse(obj)

		proc_dict={}
		nodes=xmlobj['systeminfo']['machines']['machine']

		for node in nodes:
			for n in node:
				proc=node[n]
				if (isinstance(proc, list)):
					for p in proc:
						worker=str(p['@worker'])
						status=str(p['@status'])
						join_items=project,n, worker
						item='.'.join(join_items)
						proc_dict[item]=status
				elif isinstance(proc, dict):
					worker=str(proc['@worker'])
					status=str(proc['@status'])
					join_items=project,n, worker
					item='.'.join(join_items)
					proc_dict[item]=status
				
		for i in proc_dict:
			if proc_dict[i].lower() in status_alert:
				if proc_dict[i].lower() == 'busy':
					proc_status=2
				else:
					proc_status=1
			else: 
				proc_status=0
			self.gauge(i, proc_status, tags=[tag])
