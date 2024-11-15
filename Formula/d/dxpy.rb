class Dxpy < Formula
  include Language::Python::Virtualenv

  desc "DNAnexus toolkit utilities and platform API bindings for Python"
  homepage "https://github.com/dnanexus/dx-toolkit"
  url "https://files.pythonhosted.org/packages/18/8a/6266c7959fad535dc6168b59a62a4b7a6d0b2a217707ada2c2c4fb7d5e44/dxpy-0.385.0.tar.gz"
  sha256 "6e0d06e9704e9845967caaf301e918496056ad58e15bd610fb02c3c4d775adcf"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "c765ea1a050a06efbd4d2e985548d9904cc19999b3ab40ca4c66d694fe4fecc9"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "c4a7ca556d3073af038c2370a4265de18314d932e76bf2726ac602c6610e266e"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "be4d934c969595797e040f8c30c10af203f6982fefc6e0ba6879cd1b68a9123c"
    sha256 cellar: :any_skip_relocation, sonoma:        "cdf8828de1a335a1cc95cf7bdd0a3d7cca34ef0d00d3e8c68929cc3765183f5f"
    sha256 cellar: :any_skip_relocation, ventura:       "17e8fe2b3fed8c610a6381fa22413d47c84fcab3c0e890c2f22816e19d2aca40"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "307bbaf4323e0a7b3687077e80d914baa77294c174efec9c3ac0e9814e5aeabb"
  end

  depends_on "certifi"
  depends_on "cryptography"
  depends_on "python@3.13"

  uses_from_macos "libffi"

  on_macos do
    depends_on "readline"
  end

  resource "argcomplete" do
    url "https://files.pythonhosted.org/packages/5f/39/27605e133e7f4bb0c8e48c9a6b87101515e3446003e0442761f6a02ac35e/argcomplete-3.5.1.tar.gz"
    sha256 "eb1ee355aa2557bd3d0145de7b06b2a45b0ce461e1e7813f5d066039ab4177b4"
  end

  resource "psutil" do
    url "https://files.pythonhosted.org/packages/26/10/2a30b13c61e7cf937f4adf90710776b7918ed0a9c434e2c38224732af310/psutil-6.1.0.tar.gz"
    sha256 "353815f59a7f64cdaca1c0307ee13558a0512f6db064e92fe833784f08539c7a"
  end

  resource "python-dateutil" do
    url "https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz"
    sha256 "37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3"
  end

  resource "six" do
    url "https://files.pythonhosted.org/packages/71/39/171f1c67cd00715f190ba0b100d606d440a28c93c7714febeca8b79af85e/six-1.16.0.tar.gz"
    sha256 "1e61c37477a1626458e36f7b1d82aa5c9b094fa4802892072e49de9c60c4c926"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/36/dd/a6b232f449e1bc71802a5b7950dc3675d32c6dbc2a1bd6d71f065551adb6/urllib3-2.1.0.tar.gz"
    sha256 "df7aa8afb0148fa78488e7899b2c59b5f4ffcfa82e6c54ccb9dd37c1d7b52d54"
  end

  resource "websocket-client" do
    url "https://files.pythonhosted.org/packages/20/07/2a94288afc0f6c9434d6709c5320ee21eaedb2f463ede25ed9cf6feff330/websocket-client-1.7.0.tar.gz"
    sha256 "10e511ea3a8c744631d3bd77e61eb17ed09304c413ad42cf6ddfa4c7787e8fe6"
  end

  # Replace `pipes` usage for python 3.13: https://github.com/dnanexus/dx-toolkit/pull/1410
  patch :DATA

  def install
    virtualenv_install_with_resources
  end

  test do
    dxenv = <<~EOS
      API server protocol	https
      API server host		api.dnanexus.com
      API server port		443
      Current workspace	None
      Current folder		None
      Current user		None
    EOS
    assert_match dxenv, shell_output("#{bin}/dx env")
  end
end

__END__
diff --git a/dxpy/cli/exec_io.py b/dxpy/cli/exec_io.py
index 982d60450..e1d927f01 100644
--- a/dxpy/cli/exec_io.py
+++ b/dxpy/cli/exec_io.py
@@ -22,7 +22,7 @@ from __future__ import print_function, unicode_literals, division, absolute_impo
 
 # TODO: refactor all dx run helper functions here
 
-import os, sys, json, collections, pipes
+import os, sys, json, collections, shlex
 from ..bindings.dxworkflow import DXWorkflow
 
 import dxpy
@@ -327,7 +327,7 @@ def format_choices_or_suggestions(header, items, obj_class, initial_indent=' ' *
         # TODO: in interactive prompts the quotes here may be a bit
         # misleading. Perhaps it should be a separate mode to print
         # "interactive-ready" suggestions.
-        return fill(header + ' ' + ', '.join([pipes.quote(str(item)) for item in items]),
+        return fill(header + ' ' + ', '.join([shlex.quote(str(item)) for item in items]),
                     initial_indent=initial_indent,
                     subsequent_indent=subsequent_indent)
 
diff --git a/dxpy/utils/exec_utils.py b/dxpy/utils/exec_utils.py
index ce0b9f5b7..8d02293b5 100644
--- a/dxpy/utils/exec_utils.py
+++ b/dxpy/utils/exec_utils.py
@@ -23,7 +23,7 @@ from __future__ import print_function, unicode_literals, division, absolute_impo
 import os, sys, json, re, collections, logging, argparse, string, itertools, subprocess, tempfile
 from functools import wraps
 from collections import namedtuple
-import pipes
+import shlex
 
 import dxpy
 from ..compat import USING_PYTHON2, open, Mapping
@@ -435,7 +435,7 @@ class DXExecDependencyInstaller(object):
                 dxpy.download_dxfile(bundle["id"], bundle["name"], project=dxpy.WORKSPACE_ID)
             except dxpy.exceptions.ResourceNotFound:
                 dxpy.download_dxfile(bundle["id"], bundle["name"])
-            self.run("dx-unpack {}".format(pipes.quote(bundle["name"])))
+            self.run("dx-unpack {}".format(shlex.quote(bundle["name"])))
         else:
             self.log('Skipping bundled dependency "{name}" because it does not refer to a file'.format(**bundle))
 
diff --git a/dxpy/utils/file_load_utils.py b/dxpy/utils/file_load_utils.py
index 89aed97cf..6f1566401 100644
--- a/dxpy/utils/file_load_utils.py
+++ b/dxpy/utils/file_load_utils.py
@@ -83,7 +83,7 @@ will download into the execution environment:
 from __future__ import print_function, unicode_literals, division, absolute_import
 
 import json
-import pipes
+import shlex
 import os
 import fnmatch
 import sys
@@ -401,10 +401,6 @@ def analyze_bash_vars(job_input_file, job_homedir):
     return file_key_descs, rest_hash
 
 
-#
-# Note: pipes.quote() to be replaced with shlex.quote() in Python 3
-# (see http://docs.python.org/2/library/pipes.html#pipes.quote)
-#
 def gen_bash_vars(job_input_file, job_homedir=None, check_name_collision=True):
     """
     :param job_input_file: path to a JSON file describing the job inputs
@@ -427,7 +423,7 @@ def gen_bash_vars(job_input_file, job_homedir=None, check_name_collision=True):
             result = json.dumps(dxpy.dxlink(elem))
         else:
             result = json.dumps(elem)
-        return pipes.quote(result)
+        return shlex.quote(result)
 
     def string_of_value(val):
         if isinstance(val, list):
diff --git a/dxpy/utils/local_exec_utils.py b/dxpy/utils/local_exec_utils.py
index 72d798136..6d1e6b0d9 100755
--- a/dxpy/utils/local_exec_utils.py
+++ b/dxpy/utils/local_exec_utils.py
@@ -16,7 +16,7 @@
 
 from __future__ import print_function, unicode_literals, division, absolute_import
 
-import os, sys, json, subprocess, pipes
+import os, sys, json, subprocess, shlex
 import collections, datetime
 
 import dxpy
@@ -351,9 +351,9 @@ def run_one_entry_point(job_id, function, input_hash, run_spec, depends_on, name
           if [[ $(type -t {function}) == "function" ]];
           then {function};
           else echo "$0: Global scope execution complete. Not invoking entry point function {function} because it was not found" 1>&2;
-          fi'''.format(homedir=pipes.quote(job_homedir),
-                       env_path=pipes.quote(os.path.join(job_env['HOME'], 'environment')),
-                       code_path=pipes.quote(environ['DX_TEST_CODE_PATH']),
+          fi'''.format(homedir=shlex.quote(job_homedir),
+                       env_path=shlex.quote(os.path.join(job_env['HOME'], 'environment')),
+                       code_path=shlex.quote(environ['DX_TEST_CODE_PATH']),
                        function=function)
         invocation_args = ['bash', '-c', '-e'] + (['-x'] if environ.get('DX_TEST_X_FLAG') else []) + [script]
     elif run_spec['interpreter'] == 'python2.7':
