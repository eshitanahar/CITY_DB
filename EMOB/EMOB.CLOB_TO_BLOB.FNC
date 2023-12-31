CREATE OR REPLACE FUNCTION EMOB.CLOB_TO_BLOB (p_clob_in IN CLOB)
   RETURN BLOB
IS
   v_blob             BLOB;
   v_result           BLOB;
   v_offset           INTEGER;
   v_buffer_size      BINARY_INTEGER := 48;
   v_buffer_varchar   VARCHAR2 (48);
   v_buffer_raw       RAW (48);
BEGIN
   IF p_clob_in IS NULL
   THEN
      RETURN NULL;
   END IF;

   DBMS_LOB.createtemporary (v_blob, TRUE);
   v_offset := 1;

   FOR i IN 1 .. CEIL (DBMS_LOB.getlength (p_clob_in) / v_buffer_size)
   LOOP
      DBMS_LOB.read (p_clob_in,
                     v_buffer_size,
                     v_offset,
                     v_buffer_varchar);
      v_buffer_raw := UTL_RAW.cast_to_raw (v_buffer_varchar);
      v_buffer_raw := UTL_ENCODE.base64_decode (v_buffer_raw);
      DBMS_LOB.
       writeappend (v_blob, UTL_RAW.LENGTH (v_buffer_raw), v_buffer_raw);
      v_offset := v_offset + v_buffer_size;
   END LOOP;

   v_result := v_blob;
   DBMS_LOB.freetemporary (v_blob);
   RETURN v_result;
END CLOB_TO_BLOB;
/
