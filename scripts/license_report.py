from rosdistro import get_distribution_cache
from rosdistro import get_distribution_file, get_distribution_files
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
        self.dist = get_distribution_file(index, self.distro)
        # the last distribution file is ours
        self.lcas_dist = get_distribution_files(index, self.distro)[-1]
        self.package_dict = None
        self.used_licenses = None
        self.max_depth = max_depth

    def build(self, start_pkg_name, level=0):
        if self.package_dict is None:
            self.package_dict = {}
            self.used_licenses = defaultdict(set)
            self.root = start_pkg_name
            self.unparsed_dependencies = set()
        if start_pkg_name not in self.package_dict:
            try:
                try:
                    xmlstr = self.dist_cache.release_package_xmls[start_pkg_name]
                except KeyError:
                    # key errors are expected for dependencies outside the ROS realm
                    self.unparsed_dependencies.add(start_pkg_name)
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

    def report(self):
        if self.package_dict is None:
            return None
        return pformat(self.package_dict), pformat(self.used_licenses)

    def markdown_license_report(self):
        if self.used_licenses is None:
            return None
        s = ''
        for k, v in self.used_licenses.items():
            s += '\n#### %s\n' % k
            for p in v:
                try:
                    repo = self.dist.release_packages[p].repository_name
                    url = self.dist.repositories[repo].source_repository.url
                except:
                    url = ""
                level = self.package_dict[p]['level']
                maintainers = ', '.join(self.package_dict[p]['maintainers'])
                s += '* [`%s`](%s) (depth: %s, maintainers: _%s_)\n' % (p, url, level, maintainers)
        s += '\n#### Dependencies for which no license could be found (no ROS `package.xml` in cache)\n'
        s += '\n_These licenses may have to be checked manually_\n'
        for d in self.unparsed_dependencies:
            s += '* `%s`\n' % d
        return s

    def markdown_license_report_all(self):
        pkgs = self.lcas_dist.release_packages
        report = '# License report\n\n'
        for p in pkgs.keys():
            self.package_dict = None
            self.build(p)
            report += '\n## Package "%s"\n\n' % p
            try:
                repo = self.dist.release_packages[p].repository_name
                url = self.dist.repositories[repo].source_repository.url
            except:
                url = ""
            maintainers = ', '.join(self.package_dict[p]['maintainers'])
            report += '* Maintainers: %s\n' % maintainers
            report += '* Repository: [`%s`](%s)\n' % (url, url)


            report += '\n### License Report for package "%s"\n' % p
            report += self.markdown_license_report()+'\n\n'
        return report

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Generate a license and package report in markdown from a root package.')
    parser.add_argument('--root', default=None, required=False, help='The name of the root package, e.g., "topological_navigation"')

    #parser.add_argument('name', help='The unique name of the repo')
    #parser.add_argument('type', help='The type of the repository (i.e. "git", "hg", "svn")')
    #parser.add_argument('url', help='The url of the repository')
    #parser.add_argument('version', nargs='?', help='The version')
    #parser.add_argument('status', nargs='?', help='The status', default="developed")
    args = parser.parse_args()

    try:
        b = LicenseReport()
        if args.root is None:
            print(b.markdown_license_report_all())
        else:
            b.build(args.root)
            #pkgs, licenses = b.report()
            print('\n### License Report for package "%s"\n' % args.root)
            print(b.markdown_license_report())

    except Exception as e:
        print(str(e), file=sys.stderr)
        exit(1)


# pkgs = b.get_ordered_packages()
# print(b.is_uptodate("desktop"))
# for (k,v) in pkgs:
#     #print(v)
#     pkg = v['name']

#     print(b.is_uptodate(pkg))
