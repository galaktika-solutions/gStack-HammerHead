#!/usr/bin/env python3
import os

import sphinx_rtd_theme
import django
django.setup()


VERSION = os.environ.get('VERSION')

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
]

source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = os.environ.get('COMPOSE_PROJECT_NAME')
copyright = '2018, Galaktika Solutions'
author = 'Galaktika Solutions'
today_fmt = '%Y-%m-%d'
version = VERSION
release = version

language = None

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This patterns also effect to html_static_path and html_extra_path
exclude_patterns = []

autodoc_default_flags = ['members', 'special-members']

pygments_style = 'trac'

# -- Options for HTML output ----------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.

html_theme = "sphinx_rtd_theme"
html_theme_path = [sphinx_rtd_theme.get_html_theme_path()]
