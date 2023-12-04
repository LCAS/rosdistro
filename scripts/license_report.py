from rosdistro import get_distribution_cache
from rosdistro import get_index
#from ros_buildfarm.release_job import _get_direct_dependencies, _get_downstream_package_names
#from ros_buildfarm.common import get_debian_package_name
from apt.cache import Cache
from pprint import pprint, pformat
from threading import Thread, Lock
from time import sleep

from catkin_pkg.packages import parse_package_string
import traceback
from collections import defaultdict

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
        self.package_dict = None
        self.used_licenses = None
        self.max_depth = max_depth

    def build(self, start_pkg_name, level=0):
        if self.package_dict is None:
            self.package_dict = {}
            self.used_licenses = defaultdict(set)
        if start_pkg_name not in self.package_dict:
            try:
                try:
                    xmlstr = self.dist_cache.release_package_xmls[start_pkg_name]
                except KeyError:
                    # key errors are expected for dependencies outside the ROS realm
                    return
                pkg = parse_package_string(xmlstr)
                deps = pkg.build_depends
                deps.extend(pkg.exec_depends)
                self.package_dict[start_pkg_name] = {
                    'licenses': set(pkg.licenses),
                    'dependencies': set([str(d) for d in set(deps)]),
                    'maintainers': set([m.email for m in pkg.maintainers]),
                    'authors': set([a.email for a in pkg.authors]),
                    'version': pkg.version,
                    'level': level
                }
                for l in set(pkg.licenses):
                    self.used_licenses[l].add(start_pkg_name)
                # stop recursion if max_depth is defined and reached
                if self.max_depth is not None:
                    if level >= self.max_depth:
                        return  
                # otherwise, recurse to next level of dependencies
                for d in set(deps):
                    self.build(str(d), level+1)
            except Exception as e:
                print('couldn\'t process package %s, continuing as best as we can' % start_pkg_name )
                print(traceback.format_exc())
                pass

    def report(self, pkg_name):
        if self.package_dict is None:
            self.build(pkg_name)
        return pformat(self.package_dict), pformat(self.used_licenses)

    def markdown_license_report(self, pkg_name):
        if self.package_dict is None:
            self.build(pkg_name)
        s = '# License Report, starting from package "%s"\n' % pkg_name
        for k, v in self.used_licenses.items():
            s += '\n## %s\n' % k
            for p in v:
                s += '* `%s` (%s)\n' % (p, self.package_dict[p]['level'])
        return s
        


        return pformat(self.package_dict), pformat(self.used_licenses)

b = LicenseReport()
#pkgs, licenses = b.report('topological_navigation')
pkgs, licenses = b.report('rviz2')
print(b.markdown_license_report('rviz2'))

# pkgs = b.get_ordered_packages()
# print(b.is_uptodate("desktop"))
# for (k,v) in pkgs:
#     #print(v)
#     pkg = v['name']

#     print(b.is_uptodate(pkg))
