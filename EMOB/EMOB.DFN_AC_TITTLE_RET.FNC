CREATE OR REPLACE FUNCTION EMOB.dfn_ac_tittle_ret (
   pCustNo         IN NUMBER,
   pAcHolderType   IN VARCHAR2,
   pMinorFlag      IN VARCHAR2)
   RETURN VARCHAR2
AS
   v_ac_title     VARCHAR2 (1024);
   vMinorName     VARCHAR2 (1024);
   vGurdianName   VARCHAR2 (1024);
BEGIN
   /*BEGIN
      SELECT FIRST_NAME || ' ' || LAST_NAME
        INTO vMinorName
        FROM EMOB.mb_customer_mst
       WHERE cust_no = (SELECT MINOR_CUST_NO
                          FROM EMOB.MB_CUSTOMER_MST
                         WHERE CUST_NO = pCustNo);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END;

   BEGIN
      SELECT FIRST_NAME || ' ' || LAST_NAME
        INTO vGurdianName
        FROM EMOB.mb_customer_mst
       WHERE cust_no = (SELECT GURDIAN_CUST_NO
                          FROM EMOB.MB_CUSTOMER_GURDIAN_INFO
                         WHERE CUST_NO = (SELECT MINOR_CUST_NO
                                            FROM EMOB.MB_CUSTOMER_MST
                                           WHERE CUST_NO = pCustNo));
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END;

   IF pAcHolderType = 'J' AND NVL (pMinorFlag, 'N') = 'N'
   THEN
      SELECT LISTAGG (INITCAP (first_name || ' ' || last_name), ' and ')
                WITHIN GROUP (ORDER BY FIRST_NAME)
        INTO v_ac_title
        FROM EMOB.mb_customer_mst
       WHERE cust_no = pCustNo;

      RETURN v_ac_title;
   END IF;

   IF pAcHolderType IN ('S', 'C') AND NVL (pMinorFlag, 'N') = 'N'
   THEN
      SELECT first_name || ' ' || last_name
        INTO v_ac_title
        FROM EMOB.mb_customer_mst
       WHERE cust_no = pCustNo;

      RETURN v_ac_title;
   ELSIF pAcHolderType = 'J' AND NVL (pMinorFlag, 'N') = 'Y'
   THEN
      v_ac_title := vMinorName || ' (Minor) ' || 'and ' || vGurdianName;
      RETURN v_ac_title;
   END IF;*/
   IF NVL (pMinorFlag, 'N') = 'Y'
   THEN
   SELECT first_name
        INTO v_ac_title
        FROM EMOB.mb_customer_mst
       WHERE cust_no = pCustNo;
       ELSE
       SELECT first_name || ' ' || last_name
        INTO v_ac_title
        FROM EMOB.mb_customer_mst
       WHERE cust_no = pCustNo;
END IF;
      RETURN v_ac_title;
END;
/
