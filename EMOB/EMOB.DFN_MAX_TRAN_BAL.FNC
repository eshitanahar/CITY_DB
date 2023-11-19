CREATE OR REPLACE FUNCTION EMOB.dfn_max_tran_bal (pBranchCode    VARCHAR2,
                                                  pAcTypeId      NUMBER,
                                                  pAcId          VARCHAR2,
                                                  pStartDate     DATE,
                                                  pEndDate       DATE)
   RETURN NUMBER
IS
   vAcMaxBalance   NUMBER := 0;
BEGIN
   SELECT MAX (NVL (initial_balance, 0) + NVL (balance, 0))
     INTO vAcMaxBalance
     FROM (SELECT SUM (cr_amount - dr_amount) initial_balance
             FROM (SELECT SUM (DECODE (drcr_code, 'D', tran_amt_fc, 0))
                             dr_amount,
                          SUM (DECODE (drcr_code, 'C', tran_amt_fc, 0))
                             cr_amount
                     FROM emob.mb_transaction_daily
                    WHERE     branch_code = pBranchCode
                          AND ac_type_id = pAcTypeId
                          AND ac_id = pAcId
                          AND doc_date < pStartDate
                   UNION ALL
                   SELECT SUM (DECODE (drcr_code, 'D', tran_amt_fc, 0))
                             DR_AMOUNT,
                          SUM (DECODE (drcr_code, 'C', tran_amt_fc, 0))
                             CR_AMOUNT
                     FROM emob.mb_transaction_dtl
                    WHERE     branch_code = pBranchCode
                          AND ac_type_id = pAcTypeId
                          AND ac_id = pAcId
                          AND doc_date < pStartDate)) a,
          (SELECT tran_id,
                  doc_date,
                  dr_amount,
                  cr_amount,
                  SUM (NVL (cr_amount, 0) - NVL (dr_amount, 0))
                     OVER (ORDER BY tran_id)
                     balance
             FROM (SELECT tran_id,
                          doc_date,
                          DECODE (drcr_code, 'D', tran_amt_fc, 0) dr_amount,
                          DECODE (drcr_code, 'C', tran_amt_fc, 0) cr_amount
                     FROM emob.mb_transaction_dtl
                    WHERE     branch_code = pBranchCode
                          AND ac_type_id = pAcTypeId
                          AND ac_id = pAcId
                          AND doc_date BETWEEN pStartDate AND pEndDate
                   UNION ALL
                   SELECT tran_id,
                          doc_date,
                          DECODE (drcr_code, 'D', tran_amt_fc, 0) dr_amount,
                          DECODE (drcr_code, 'C', tran_amt_fc, 0) cr_amount
                     FROM emob.mb_transaction_daily
                    WHERE     branch_code = pBranchCode
                          AND ac_type_id = pAcTypeId
                          AND ac_id = pAcId
                          AND doc_date BETWEEN pStartDate AND pEndDate
                   ORDER BY tran_id)) b;
                   RETURN vAcMaxBalance;
EXCEPTION
   WHEN OTHERS
   THEN
       RETURN vAcMaxBalance;
END;
/
