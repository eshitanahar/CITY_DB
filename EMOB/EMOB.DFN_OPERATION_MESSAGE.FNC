CREATE OR REPLACE FUNCTION EMOB.DFN_OPERATION_MESSAGE (pMessageId IN VARCHAR2)
   RETURN VARCHAR2
IS
   vCustomerMsgCode   VARCHAR2 (1024);
BEGIN
   BEGIN
      SELECT MESSAGE_CODE
        INTO vCustomerMsgCode
        FROM EMOB.ST_OPERATION_MESSAGE_INFO
       WHERE MESSAGE_ID = pMessageId;
   EXCEPTION
      WHEN OTHERS
      THEN
         vCustomerMsgCode := 'Unable To Display Proper Message';
   END;

   RETURN vCustomerMsgCode;
END;
/
