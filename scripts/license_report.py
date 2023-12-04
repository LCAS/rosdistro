from rosdistro import get_distribution_cache
from rosdistro import get_index
#from ros_buildfarm.release_job import _get_direct_dependencies, _get_downstream_package_names
#from ros_buildfarm.common import get_debian_package_name
from apt.cache import Cache
from pprint import pprint, pformat
from threading import Thread, Lock
from time import sleep

from catkin_pkg.packages import parse_package_string


import sys
from os import environ


class LicenseReport:

    def __init__(self, rosdistro_index_url=None, distro=None, max_depth=None):
        if distro is None:
            distro = environ.get('ROS_DISTRO', 'humble')
        self.distro = distro
        if rosdistro_index_url is None:
            rosdistro_index_url = environ.get('ROSDISTRO_INDEX_URL', 'https://raw.githubusercontent.com/LCAS/rosdistro/master/index-v4.yaml')
        self.rosdistro_index_url = rosdistro_index_url

        index = get_index(self.rosdistro_index_url)
        self.dist_cache = get_distribution_cache(index, self.distro)
        self.license_dict = None
        self.max_depth = max_depth

    def build(self, start_pkg_name, level=0):
        if self.license_dict is None:
            self.license_dict = []
        if start_pkg_name not in self.license_dict:
            try:
                xmlstr = self.dist_cache.release_package_xmls[start_pkg_name]
                pkg = parse_package_string(xmlstr)
                deps = pkg.build_depends
                deps.extend(pkg.exec_depends)
                self.license_dict[start_pkg_name] = {
                    'licenses': set(pkg.licenses),
                    'dependencies': set([str(d) for d in set(deps)]),
                    'maintainers': set([m.email for m in pkg.maintainers]),
                    'authors': set([a.email for a in pkg.authors]),
                    'version': pkg.version,
                    'level': level
                }
                # stop recursion if max_depth is defined and reached
                if self.max_depth is not None:
                    if level >= self.max_depth:
                        return  
                # otherwise, recurse to next level of dependencies
                for d in set(deps):
                    self.build(str(d), level+1)
            except:
                print('couldn\'t process package %s, continuing as best as we can' % start_pkg_name )
                pass

    def report(self, pkg_name):
        if self.license_dict is None:
            self.build(pkg_name)
        return pformat(self.license_dict)


b = LicenseReport()
print(b.report('topological_navigation'))

# pkgs = b.get_ordered_packages()
# print(b.is_uptodate("desktop"))
# for (k,v) in pkgs:
#     #print(v)
#     pkg = v['name']

#     print(b.is_uptodate(pkg))
