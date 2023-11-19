CREATE OR REPLACE FUNCTION EMOB.dfn_avg_bal1 (p_brancd     VARCHAR2,
                                              p_actype     NUMBER,
                                              p_actnum     VARCHAR2,
                                              p_from_dt    DATE,
                                              p_to_dt      DATE)
   RETURN NUMBER
IS
   vnm_avg       NUMBER;
   v_from_dt     DATE;
   v_ac_id       NUMBER;
   v_tran_date   DATE;
BEGIN
   BEGIN
      SELECT AC_ID
        INTO v_ac_id
        FROM emob.MB_ACCOUNT_MST
       WHERE     BRANCH_CODE = p_brancd
             AND AC_TYPE_ID = p_actype
             AND AC_NO = p_actnum;
   EXCEPTION
      WHEN OTHERS
      THEN
         vnm_avg := 0;
   END;

   BEGIN
      SELECT MIN (DOC_DATE)
        INTO v_tran_date
        FROM (SELECT DOC_DATE
                FROM EMOB.MB_TRANSACTION_DTL
               WHERE     BRANCH_CODE = p_brancd
                     AND AC_TYPE_ID = p_actype
                     AND AC_ID = v_ac_id
                     AND NVL(BAL_FLAG,'N' )='Y'
              UNION ALL
              SELECT DOC_DATE
                FROM EMOB.MB_TRANSACTION_DAILY
               WHERE     BRANCH_CODE = p_brancd
                     AND AC_TYPE_ID = p_actype
                     AND AC_ID = v_ac_id
                     AND NVL(BAL_FLAG,'N' )='Y');
   END;

   IF v_tran_date > p_from_dt
   THEN
      v_from_dt := v_tran_date;
   ELSE
      v_from_dt := p_from_dt;
   END IF;

   BEGIN
      SELECT ROUND (SUM (balance) / SUM (no_of_days), 2)
        INTO vnm_avg
        FROM (SELECT start_date,
                     end_date,
                     no_of_days,
                     account_balance * no_of_days balance
                FROM (  SELECT doc_date,
                               TRUNC (doc_date, 'DD') start_date,
                               TRUNC (
                                  (LEAD (doc_date - 1, 1, p_to_dt)
                                      OVER (ORDER BY doc_date)),
                                  'DD')
                                  end_date,
                               TRUNC (
                                  (NVL (
                                      LEAD (doc_date + 1)
                                         OVER (ORDER BY doc_date),
                                      (p_to_dt + 2))
                                   - (doc_date + 1)))
                                  no_of_days,
                               tran_amt days_balance,
                               SUM (tran_amt) OVER (ORDER BY doc_date)
                                  account_balance
                          FROM (SELECT v_from_dt doc_date,
                                       SUM (
                                          DECODE (drcr_code,
                                                  'C', tran_amt_fc,
                                                  0))
                                       - SUM (
                                            DECODE (drcr_code,
                                                    'D', tran_amt_fc,
                                                    0))
                                          tran_amt
                                  FROM (SELECT doc_date,
                                               create_date,
                                               drcr_code,
                                               tran_amt_fc
                                          FROM emob.mb_transaction_daily
                                         WHERE   BRANCH_CODE = p_brancd AND  AC_TYPE_ID = p_actype AND ac_id = v_ac_id
                                               AND NVL (bal_flag, 'N') = 'Y'
                                               AND doc_date < v_from_dt
                                        UNION ALL
                                        SELECT doc_date,
                                               create_date,
                                               drcr_code,
                                               tran_amt_fc
                                          FROM emob.mb_transaction_dtl
                                         WHERE    BRANCH_CODE = p_brancd AND  AC_TYPE_ID = p_actype AND ac_id = v_ac_id
                                               AND NVL (bal_flag, 'N') = 'Y'
                                               AND doc_date < v_from_dt
                                        ORDER BY 1, 2)
                                UNION ALL
                                  SELECT doc_date,
                                         SUM (
                                            DECODE (drcr_code,
                                                    'C', tran_amt_fc,
                                                    0))
                                         - SUM (
                                              DECODE (drcr_code,
                                                      'D', tran_amt_fc,
                                                      0))
                                            tran_amta
                                    FROM (SELECT doc_date,
                                                 create_date,
                                                 drcr_code,
                                                 tran_amt_fc
                                            FROM emob.mb_transaction_daily
                                           WHERE BRANCH_CODE = p_brancd AND AC_TYPE_ID = p_actype AND ac_id = v_ac_id
                                                 AND NVL (bal_flag, 'N') = 'Y'
                                                 AND doc_date BETWEEN v_from_dt
                                                                  AND p_to_dt
                                          UNION ALL
                                          SELECT doc_date,
                                                 create_date,
                                                 drcr_code,
                                                 tran_amt_fc
                                            FROM emob.mb_transaction_dtl
                                           WHERE BRANCH_CODE = p_brancd AND AC_TYPE_ID = p_actype AND ac_id = v_ac_id
                                                 AND NVL (bal_flag, 'N') = 'Y'
                                                 AND doc_date BETWEEN v_from_dt
                                                                  AND p_to_dt
                                          ORDER BY 1, 2)
                                GROUP BY doc_date
                                ORDER BY 1)
                      ORDER BY 1));
   EXCEPTION
      WHEN OTHERS
      THEN
         vnm_avg := 0;
   END;

   RETURN NVL (vnm_avg, 0);
END;
/
