#!/usr/bin/python
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is based on
#
# https://github.com/apache/ranger/blob/master/security-admin/scripts/update_property.py
#
# See the NOTICE file distributed with this work for additional information regarding copyright ownership.

import sys
import os
from xml.etree import ElementTree as ET
from xml.parsers.expat import ExpatError

def write_properties_to_xml(xml_path, property_name='', property_value='', append=False):
    if os.path.isfile(xml_path):
        try:            
            xml = ET.parse(xml_path)
        except ExpatError:
            print("Error while parsing file:" + xml_path)
            return -1
        
        property_exists = False
        root = xml.getroot()
        
        for child in root.findall('property'):
            name = child.find("name").text.strip()
            if name == property_name:
                property_exists = True
                value_element = child.find("value")

                if value_element is None:
                    # If <value> does not exist, create it
                    value_element = ET.SubElement(child, "value")
                    current_value = ''
                else:
                    current_value = value_element.text if value_element.text else ''
                    current_value = current_value.strip()
                
                if append:
                    # Append the new value to the existing one, separated by commas
                    if current_value:
                        new_value = current_value + ',' + property_value
                    else:
                        new_value = property_value
                else:
                    new_value = property_value

                value_element.text = new_value
                break
        
        if not property_exists:
            new_property = ET.SubElement(root, 'property')
            ET.SubElement(new_property, 'name').text = property_name     
            ET.SubElement(new_property, 'value').text = property_value 
        
        xml.write(xml_path)
        return 0
    else:    
        return -1



if __name__ == '__main__':
    if len(sys.argv) > 1:
        append_mode = '--append' in sys.argv  # Check if '--append' is passed
        if append_mode:
            sys.argv.remove('--append')

        if len(sys.argv) > 3:
            parameter_name = sys.argv[1] if len(sys.argv) > 1 else None
            parameter_value = sys.argv[2] if len(sys.argv) > 2 else None
            file_xml_path = sys.argv[3] if len(sys.argv) > 3 else None
        else:
            if len(sys.argv) > 2:
                parameter_name = sys.argv[1] if len(sys.argv) > 1 else None
                parameter_value = ""
                file_xml_path = sys.argv[2] if len(sys.argv) > 2 else None
        
        write_properties_to_xml(file_xml_path, parameter_name, parameter_value, append=append_mode)
