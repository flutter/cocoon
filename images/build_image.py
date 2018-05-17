#!/usr/bin/python2.7

import os.path
import shutil
import subprocess
import sys
import tempfile


# Returns the image tools directory (where this script is located).
def get_tools_dir():
  return os.path.dirname(os.path.abspath(__file__))


# Returns the root directory of the Cocoon repo.
def get_repo_root_dir():
  p = subprocess.Popen(['git', 'rev-parse', '--show-toplevel'], stdout=subprocess.PIPE)
  out, err = p.communicate()
  return out.strip()


# Creates a sparseimage with the specified volume name at out_path.
def create_sparse_dmg(name, out_path):
  print('Creating disk image (%s)...' % out_path)
  return subprocess.call([
    'hdiutil', 'create',
    '-volname', name,
    '-type', 'SPARSE',
    '-layout', 'GPTSPUD',
    '-fs', 'APFS',
    '-size', '4g',
    out_path,
  ])


# Creates a disk image from the specified directory contents.
def create_disk_image(name, src_dir, out_path):
   print('Creating disk image (%s)...' % out_path)
   return subprocess.call([
     'hdiutil', 'create',
     '-volname', name,
     '-layout', 'GPTSPUD',
     '-format', 'ULFO',
     '-fs', 'APFS',
     '-srcfolder', src_dir,
     out_path,
   ])


# Mounts the specified disk image.
def mount_dmg(dmg_path):
  print('Mounting disk image (%s)...' % dmg_path)
  return subprocess.call(['hdiutil', 'attach', dmg_path])


# Unmounts the specified disk image.
def unmount_dmg(mount_path):
  print('Unmounting disk image (%s)...' % mount_path)
  return subprocess.call(['hdiutil', 'detach', mount_path])


# Reads a one-line file containing a version number.
def read_version_file(file_path):
  with open(file_path, 'r') as version_file:
    return version_file.read().strip()


# Downloads a file from the specified URL to the specified path on disk.
def download_archive(url, out_path):
  return subprocess.call(['curl', url, '-o', out_path])


# Downloads the specified (dev) version of the Dart SDK.
def download_dart_sdk(version, out_zip):
  channel = 'dev'
  archive = 'dartsdk-macos-x64-release.zip'
  dl_uri = 'https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/%s' % (channel, version, archive)
  download_archive(dl_uri, out_zip)


# Downloads the specified version of the Android SDK tools bundle.
def download_android_sdk(version, out_zip):
  archive = 'sdk-tools-darwin-%s.zip' % version
  dl_uri = 'https://dl.google.com/android/repository/%s' % archive
  download_archive(dl_uri, out_zip)


# Unzips the specified zip archive in place, then deletes the archive.
def unzip_in_place(zip_path):
  zip_dir = os.path.abspath(os.path.dirname(zip_path))
  subprocess.call(['unzip', zip_path, '-d', zip_dir])
  os.remove(zip_path)


# Copy all files in one src_dir to dst_dir.
def copy_dir_contents(src_dir, dst_dir):
  print('Copying files...')
  for fname in os.listdir(src_dir):
    print('... ' + fname)
    fsrc = os.path.join(src_dir, fname)
    fdst = os.path.join(dst_dir, fname)
    shutil.copyfile(fsrc, fdst)
    shutil.copymode(fsrc, fdst)


# Creates a DevicelabCore disk image in the specified output directory.
def create_image_core(output_dir):
  image_name = 'DevicelabCore'
  image_path = os.path.join(output_dir, image_name + '.dmg')
  if os.path.isfile(image_path):
    print('ERROR: Output disk image already exists: %s' % image_path)
    exit(1)

  # Create and mount a working disk image.
  sparseimage_path = os.path.join(output_dir, image_name + '.sparseimage')
  if os.path.isfile(sparseimage_path):
    os.remove(sparseimage_path)
  create_sparse_dmg(image_name, sparseimage_path);
  mount_dmg(sparseimage_path)
  work_dir = os.path.join('/Volumes', image_name)
  print('Working directory: ' + work_dir)

  # Copy checked-in files.
  core_files_dir = os.path.join(get_tools_dir(), 'core')
  copy_dir_contents(core_files_dir, work_dir)

  # Copy cocoon repo.
  print('Cloning cocoon repo...')
  repo_root = get_repo_root_dir()
  cocoon_out = os.path.join(work_dir, 'cocoon')
  subprocess.call(['git', 'clone', repo_root, os.path.join(work_dir, 'cocoon')])
  shutil.rmtree(os.path.join(cocoon_out, '.git'))

  # Download and unzip Dart SDK.
  dart_version_path = os.path.join(get_tools_dir(), 'dart_version')
  dart_version = read_version_file(dart_version_path)
  print('Downloading Dart SDK %s...' % dart_version)
  dart_sdk_zip = os.path.join(work_dir, 'dart-sdk.zip')
  download_dart_sdk(dart_version, dart_sdk_zip)
  unzip_in_place(dart_sdk_zip)

  # Convert the disk image to read-only.
  create_disk_image(image_name, work_dir, image_path)
  unmount_dmg(work_dir)
  os.remove(sparseimage_path)


# Creates a DevicelabIOS disk image in the specified output directory.
def create_image_ios(output_dir):
  image_name = 'DevicelabIOS'
  image_path = os.path.join(output_dir, image_name + '.dmg')
  if os.path.isfile(image_path):
    print('ERROR: Output disk image already exists: %s' % image_path)
    exit(1)

  # Create and mount a working disk image.
  sparseimage_path = os.path.join(output_dir, image_name + '.sparseimage')
  if os.path.isfile(sparseimage_path):
    os.remove(sparseimage_path)
  create_sparse_dmg(image_name, sparseimage_path);
  mount_dmg(sparseimage_path)
  work_dir = os.path.join('/Volumes', image_name)
  print('Working directory: ' + work_dir)

  # Copy checked-in files.
  print('Copying files...')
  ios_files_dir = os.path.join(get_tools_dir(), 'ios')
  copy_dir_contents(ios_files_dir, work_dir)

  # Install homebrew.
  print('Cloning Homebrew...')
  homebrew_dir = os.path.join(work_dir, 'homebrew')
  homebrew_tar = os.path.join(work_dir, 'homebrew.tar.gz')
  os.mkdir(homebrew_dir)
  subprocess.call(['curl', '-L', 'https://github.com/Homebrew/brew/tarball/master', '-o', homebrew_tar])
  subprocess.call(['tar', 'zxf', homebrew_tar, '--strip', '1', '-C', homebrew_dir])
  os.remove(homebrew_tar)

  print('Installing Homebrew packages...')
  homebrew_packages_path = os.path.join(get_tools_dir(), 'homebrew_packages')

  # Read packages file.
  packages = []
  with open(homebrew_packages_path, 'r') as pkg_file:
    packages = pkg_file.read().strip().split('\n')
  install_pkgs = [p for p in packages if not p[0] == '-']
  remove_pkgs = [p[1:] for p in packages if p[0] == '-']

  # Perform installation, any post-install removals, and cleanup.
  proc_env = {
    'HOME': work_dir,
    'PATH': '%s:/sbin:/usr/sbin:/bin:/usr/bin' % os.path.join(homebrew_dir, 'bin'),
  }
  brew_path = os.path.join(homebrew_dir, 'bin', 'brew')
  for p in install_pkgs:
    flags = []
    if ':' in p:
      (p, flags) = p.split(':', 1)
      flags = flags.split(' ')
    sdkmgr_proc = subprocess.Popen([brew_path, 'install'] + flags + [p], env=proc_env)
    sdkmgr_proc.communicate()
  for p in remove_pkgs:
    sdkmgr_proc = subprocess.Popen([brew_path, 'uninstall', '--force', '--ignore-dependencies', p], env=proc_env)
    sdkmgr_proc.communicate()
  sdkmgr_proc = subprocess.Popen([brew_path, 'cleanup'], env=proc_env)
  sdkmgr_proc.communicate()

  # Install Cocoapods.
  print('Cloning Cocoapods...')
  cocoapods_version_path = os.path.join(get_tools_dir(), 'cocoapods_version')
  cocoapods_version = read_version_file(cocoapods_version_path)
  proc_env = {
    'HOME': work_dir,
    'PATH': '/sbin:/usr/sbin:/bin:/usr/bin',
  }
  gem_proc = subprocess.Popen(
    ['/usr/bin/gem', 'install', 'cocoapods', '-v', cocoapods_version, '--user-install'],
    env=proc_env,
  )
  gem_proc.communicate()
  os.rename(os.path.join(work_dir, '.gem'), os.path.join(work_dir, 'gem'))

  # Convert the disk image to read-only.
  create_disk_image(image_name, work_dir, image_path)
  unmount_dmg(work_dir)
  os.remove(sparseimage_path)


# Creates a DevicelabAndroid disk image in the specified output directory.
def create_image_android(output_dir):
  image_name = 'DevicelabAndroid'
  image_path = os.path.join(output_dir, image_name + '.dmg')
  if os.path.isfile(image_path):
    print('ERROR: Output disk image already exists: %s' % image_path)
    exit(1)

  # Create and mount a working disk image.
  sparseimage_path = os.path.join(output_dir, image_name + '.sparseimage')
  if os.path.isfile(sparseimage_path):
    os.remove(sparseimage_path)
  create_sparse_dmg(image_name, sparseimage_path);
  mount_dmg(sparseimage_path)
  work_dir = os.path.join('/Volumes', image_name)
  print('Working directory: ' + work_dir)

  # Copy checked-in files.
  android_files_dir = os.path.join(get_tools_dir(), 'android')
  copy_dir_contents(android_files_dir, work_dir)

  print('Downloading Android SDK tools...')
  android_sdk_dir = os.path.join(work_dir, 'sdk')
  os.mkdir(android_sdk_dir)
  android_sdk_zip = os.path.join(android_sdk_dir, 'android-sdk.zip')
  android_version_path = os.path.join(get_tools_dir(), 'android_sdk_tools_version')
  android_version = read_version_file(android_version_path)
  download_android_sdk(android_version, android_sdk_zip)
  unzip_in_place(android_sdk_zip)

  print('Accepting licenses...')
  sdkmgr_path = os.path.join(android_sdk_dir, 'tools', 'bin', 'sdkmanager')
  sdkmgr_proc = subprocess.Popen([sdkmgr_path, '--sdk_root=%s' % android_sdk_dir, '--licenses'], stdin=subprocess.PIPE)
  sdkmgr_proc.communicate('y\n' * 20)

  print('Downloading Android SDK packages...')
  android_packages_path = os.path.join(get_tools_dir(), 'android_sdk_packages')
  proc_env = {
    'HOME': work_dir,
    'PATH': '/sbin:/usr/sbin:/bin:/usr/bin',
  }
  packages = []
  with open(android_packages_path, 'r') as pkg_file:
    packages = pkg_file.read().strip().split('\n')
  for p in packages:
    sdkmgr_proc = subprocess.Popen([sdkmgr_path, '--sdk_root=%s' % android_sdk_dir, p], env=proc_env)
    sdkmgr_proc.communicate()

  # Convert the disk image to read-only.
  create_disk_image(image_name, work_dir, image_path)
  unmount_dmg(work_dir)
  os.remove(sparseimage_path)


def exit_with_usage():
  print('usage: %s core|ios|android' % sys.argv[0])
  exit(1)


def main():
  # Bail out if we're not running Python 2.7.
  assert sys.version_info >= (2, 7) and sys.version_info < (3, 0)

  args = sys.argv[1:]
  if len(args) < 1:
    exit_with_usage()

  output_dir = os.getcwd()
  image_type = args[0]
  if image_type == 'core':
    create_image_core(output_dir)
  elif image_type == 'ios':
    create_image_ios(output_dir)
  elif image_type == 'android':
    create_image_android(output_dir)
  else:
    exit_with_usage()


if __name__ == '__main__':
  main()
