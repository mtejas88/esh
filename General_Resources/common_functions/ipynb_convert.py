import nbformat
from nbconvert import PythonExporter
import sys
import os

#converts a jupyter notebook (with path string notebookPath) to a python (.py) file with the path string modulePath
def convertNotebook(notebookPath, modulePath):

  with open(notebookPath) as fh:
    nb = nbformat.reads(fh.read(), nbformat.NO_CONVERT)

  exporter = PythonExporter()
  source, meta = exporter.from_notebook_node(nb)

  with open(modulePath, 'w+') as fh:
    fh.writelines(source)

#executes converting a jupyter notebook on a notebook with notebookName as it name (string), converting to a python file with moduleName as its name (string)
def executeConvertNotebook(notebookName,moduleName,main):
	if hasattr(main, '__file__') is False:
	    notebookPath=os.path.join(os.getcwd(), notebookName)
	    modulePath=os.path.join(os.getcwd(), moduleName)
	    convertNotebook(notebookPath,modulePath)
