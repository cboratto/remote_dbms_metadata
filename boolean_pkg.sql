CREATE OR REPLACE PACKAGE BODY MONITOR_ADM.boolean_pkg
IS
   c_true    CONSTANT VARCHAR2 (5) := 'TRUE';
   c_false   CONSTANT VARCHAR2 (5) := 'FALSE';

/***************************************************/
   FUNCTION bool_to_str (boolean_in IN BOOLEAN)
      RETURN VARCHAR2
   IS
   BEGIN
      IF boolean_in
      THEN
         RETURN c_true;
      ELSIF NOT boolean_in
      THEN
         RETURN c_false;
      ELSE
         RETURN NULL;
      END IF;
   END bool_to_str;

/***************************************************/
   FUNCTION str_to_bool (string_in IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF string_in = c_true
      THEN
         RETURN TRUE;
      ELSIF string_in = c_false
      THEN
         RETURN FALSE;
      ELSE
         RETURN NULL;
      END IF;
   END str_to_bool;

/***************************************************/
   FUNCTION true_value
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN c_true;
   END true_value;

   FUNCTION false_value
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN c_false;
   END false_value;
/***************************************************/

END boolean_pkg;
/
