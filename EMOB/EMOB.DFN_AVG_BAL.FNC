CREATE OR REPLACE FUNCTION EMOB.dfn_avg_bal (
   p_brancd    VARCHAR2,
   p_actype    number,
   p_actnum    VARCHAR2,
   p_from_dt   DATE,
   p_to_dt     DATE
)
   RETURN NUMBER
IS
   vnm_avg     NUMBER;
   v_from_dt   DATE;
   v_opn_dt    DATE;
   v_ac_id number;
BEGIN
   BEGIN
      SELECT trunc(OPEN_DATE),AC_ID 
        INTO v_opn_dt,  v_ac_id
        FROM emob.MB_ACCOUNT_MST
       WHERE BRANCH_CODE = p_brancd AND AC_TYPE_ID = p_actype AND AC_NO = p_actnum;

      IF v_opn_dt > p_from_dt THEN
         v_from_dt := v_opn_dt;
      ELSE
         v_from_dt := p_from_dt;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         vnm_avg := 0;
   END;

   BEGIN
      SELECT SUM (day_cnt * cum_bal) / SUM (day_cnt) avg_bal
        INTO vnm_avg
        FROM (SELECT doc_date,
                     (  NVL (LEAD (doc_date + 1) OVER (ORDER BY doc_date),
                             (p_to_dt + 2
                             )
                            )
                      - (DOC_DATE + 1)
                     ) day_cnt,
                     tran_amt, SUM (tran_amt) OVER (ORDER BY DOC_DATE) cum_bal
                FROM (SELECT   v_from_dt DOC_DATE,
                                SUM (decode(drcr_code,'C',TRAN_AMT_LC,0)) - SUM (decode(drcr_code,'D',TRAN_AMT_LC,0)) tran_amt
                          FROM emob.MB_TRANSACTION_DTL
                         WHERE BRANCH_CODE = p_brancd
                           AND AC_TYPE_ID = p_actype
                           AND ac_id = v_ac_id
                           AND DOC_DATE < v_from_dt
                           and AC_ID is not null
                      UNION ALL
                      SELECT   DOC_DATE, SUM (decode(drcr_code,'C',TRAN_AMT_LC,0)) - SUM (decode(drcr_code,'D',TRAN_AMT_LC,0)) tran_amt
                          FROM emob.MB_TRANSACTION_DTL
                         WHERE BRANCH_CODE = p_brancd
                           AND AC_TYPE_ID = p_actype
                           AND AC_ID = v_ac_id
                           and AC_ID is not null
                           AND doc_date BETWEEN v_from_dt AND p_to_dt
                      GROUP BY doc_date
                      ORDER BY 1));
   EXCEPTION
      WHEN OTHERS THEN
         vnm_avg := 0;
   END;

   RETURN ROUND (ABS (NVL (vnm_avg, 0)));
END;
/
