from rosdistro import get_distribution_cache
from rosdistro import get_index
from ros_buildfarm.release_job import _get_direct_dependencies, _get_downstream_package_names
from ros_buildfarm.common import get_debian_package_name
from apt.cache import Cache
from pprint import pprint
from threading import Thread, Lock
from time import sleep


import sys
from os import environ


class LicenseReport:

    def __init__(self, rosdistro_index_url=None, distro = None):
        if distro is None:
            distro = environ.get('ROS_DISTRO', 'humble')
        self.distro = distro
        if rosdistro_index_url is None:
            rosdistro_index_url = environ.get('ROSDISTRO_INDEX_URL', 'https://raw.githubusercontent.com/LCAS/rosdistro/master/index-v4.yaml')
        self.rosdistro_index_url = rosdistro_index_url

        index = get_index(self.rosdistro_index_url)
        self.dist_cache = get_distribution_cache(index, self.distro)

    def report(self, pkg_name):
        print(self.dist_cache.distribution_file.repositories['topological_navigation'])


b = LicenseReport()
b.report('topological_navigation')

# pkgs = b.get_ordered_packages()
# print(b.is_uptodate("desktop"))
# for (k,v) in pkgs:
#     #print(v)
#     pkg = v['name']

#     print(b.is_uptodate(pkg))
