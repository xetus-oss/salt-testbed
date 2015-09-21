# Place defaults you may want to import across different pillar files
# here
{%- load_yaml as defaults %}
pillar_files: /vagrant/salt/pillar_files
{%- endload %}