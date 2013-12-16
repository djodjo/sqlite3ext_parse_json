/*
 * sqlite3_parse_json (https://github.com/djodjo/sqlite3ext_parse_json)
 * Copyright (c) 2013 Motoshige SUZUKI
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Acknowledgement.
 *   This code makes use of the following third party libraries.
 *   Parson ( http://kgabis.github.com/parson/ )
 *
*/

#include <sqlite3ext.h>
#include <parson.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

SQLITE_EXTENSION_INIT1

/*
** The JSON Parser SQL function.
*/
static void parse_jsonFunc(
	sqlite3_context *context,
	int argc,
	sqlite3_value **argv
){
    JSON_Value     *root_value;
	JSON_Object    *json_object;
	JSON_Value     *json_value;
	JSON_Value_Type json_type;

	root_value = json_parse_string((const char *)sqlite3_value_text(argv[0]));
	if(root_value == NULL){
		sqlite3_result_null(context);		
		json_value_free(root_value);
		return;
	}
	json_object = json_value_get_object(root_value);

	json_value = json_object_dotget_value(json_object,(const char *)sqlite3_value_text(argv[1]));
	json_type = json_value_get_type(json_value);

	if(json_type == JSONNumber){
		sqlite3_result_double(context,json_value_get_number(json_value) );

	}else if(json_type == JSONBoolean){
		sqlite3_result_int(context,json_value_get_boolean(json_value) );
	
	}else if(json_type == JSONNull){
		sqlite3_result_null(context);

	}else{
		const char* str = json_value_get_string(json_value);
		sqlite3_result_text(context, str, -1, SQLITE_TRANSIENT);
	}	
    json_value_free(root_value);
	return;
}

/* SQLite invokes this routine once when it loads the extension.
** Create new functions, collating sequences, and virtual table
** modules here.  This is usually the only exported symbol in
** the shared library.
*/
int sqlite3_extension_init(
  sqlite3 *db,
  char **pzErrMsg,
  const sqlite3_api_routines *pApi
){
  SQLITE_EXTENSION_INIT2(pApi)
  sqlite3_create_function(db, "parse_json", 2, SQLITE_ANY, 0, parse_jsonFunc, 0, 0);
  return 0;
}
