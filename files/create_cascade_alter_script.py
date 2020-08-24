#!/usr/bin/python
#
# Copyright (C) 2018-2020 Expedia, Inc.
#
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

import argparse
import re

CREATE_REGEX         = r'\s*CREATE TABLE IF NOT EXISTS\s+([^\(\s]+)\s*\('
FOREIGN_KEY_REGEX    = r'^\s*(CONSTRAINT\s+([^\s]+)\s*FOREIGN KEY\s+([^\s]+)\s+REFERENCES[^,\r\n]*),*$'
CASCADE_DELETE_REGEX = r'.*ON DELETE CASCADE.*'
SQL_STMT_END_REGEX   = r'.*;\s*$'

def generate_alter_table_scripts(hive_schema_input_file):
    regex_create  = re.compile(CREATE_REGEX, re.IGNORECASE)
    regex_fk      = re.compile(FOREIGN_KEY_REGEX, re.IGNORECASE)
    regex_cascade = re.compile(CASCADE_DELETE_REGEX, re.IGNORECASE)
    regex_endstmt = re.compile(SQL_STMT_END_REGEX, re.IGNORECASE)

    with open(hive_schema_input_file, 'r') as sql_file:
        lines = sql_file.readlines()

    with open('cascadedeletes.sql', 'w') as f_cascade, open('undo_cascadedeletes.sql', 'w') as f_undo_cascade:
        in_create_stmt = False
        table_name = None

        for line in lines:
            create_match = regex_create.match(line)
            if create_match is not None:
                in_create_stmt = True
                if len(create_match.groups()) == 1:
                    table_name = create_match.group(1)
                pass

            fk_match = regex_fk.match(line)
            if fk_match is not None:
                # Check if it already specifies cascading deletes
                cascade_match = regex_cascade.match(line)
                if cascade_match is None:
                    grps = fk_match.groups()
                    if len(grps) == 3:
                        constraint_stmt = grps[0]
                        fk_name = grps[1]
                        if in_create_stmt and table_name is not None:
                            f_cascade.write('ALTER TABLE {} DROP FOREIGN KEY {};\n'.format(table_name, fk_name))
                            f_cascade.write('ALTER TABLE {} ADD {} ON DELETE CASCADE;\n'.format(table_name, constraint_stmt))

                            f_undo_cascade.write('ALTER TABLE {} DROP FOREIGN KEY {};\n'.format(table_name, fk_name))
                            f_undo_cascade.write('ALTER TABLE {} ADD {};\n'.format(table_name, constraint_stmt))

            end_stmt_match = regex_endstmt.match(line)
            if end_stmt_match is not None:
                in_create_stmt = False;
                table_name = None


def main():
    parser = argparse.ArgumentParser(description='Get cmdline args for script')
    parser.add_argument("hive_schema_input_file", help="Path to Hive Schema file used to create cascading delete updates")
    args = parser.parse_args()

    generate_alter_table_scripts(args.hive_schema_input_file)

if __name__ == "__main__":
    main()
