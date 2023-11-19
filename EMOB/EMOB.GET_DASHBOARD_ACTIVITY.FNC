CREATE OR REPLACE FUNCTION EMOB.GET_DASHBOARD_ACTIVITY(pOutLet VARCHAR2,pDate DATE) 
RETURN CLOB 
IS 
vContent CLOB; 
BEGIN 
   
   /* FOR CASA */ 
for i  in( 
  SELECT (SELECT COUNT (AC_ID) 
          FROM EMOB.MB_ACCOUNT_MST a, EMOB.ST_AGENT_POINT p 
         WHERE     A.POINT_ID = P.POINT_ID 
               AND SUBSTR (ac_No, 5, 1) IN (1, 2, 3) 
               AND p.POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', p.POINT_ID, 
                              pOutLet) 
               AND TO_CHAR (A.FINAL_CHECK_DATE, 'DD-MM-YYYY') = 
                      TO_CHAR (pDate, 'DD-MM-YYYY') 
               AND A.AC_STATUS = 'ACT') 
          casa_today, 
       (SELECT COUNT (AC_ID) 
          FROM EMOB.MB_ACCOUNT_MST a, EMOB.ST_AGENT_POINT p 
         WHERE     A.POINT_ID = P.POINT_ID 
               AND SUBSTR (ac_No, 5, 1) IN (1, 2, 3) 
               AND p.POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', p.POINT_ID, 
                              pOutLet) 
               AND trunc(FINAL_CHECK_DATE)<trunc(pDate) 
               AND A.AC_STATUS = 'ACT') 
          CASA_TOTAL, 
       (SELECT COUNT (AC_ID) 
          FROM EMOB.MB_ACCOUNT_MST a, EMOB.ST_AGENT_POINT p 
         WHERE     A.POINT_ID = P.POINT_ID 
               AND SUBSTR (ac_No, 5, 1) = 4 
               AND p.POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', p.POINT_ID, 
                              pOutLet) 
               AND TRUNC(A.FINAL_CHECK_DATE) < TRUNC(pDate) 
               AND A.AC_STATUS = 'ACT') 
          Fixed_dep_total, 
       (SELECT COUNT (AC_ID) 
          FROM EMOB.MB_ACCOUNT_MST a, EMOB.ST_AGENT_POINT p 
         WHERE     A.POINT_ID = P.POINT_ID 
               AND SUBSTR (ac_No, 5, 1) = 4 
               AND p.POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', p.POINT_ID, 
                              pOutLet) 
               AND TRUNC(A.FINAL_CHECK_DATE) = TRUNC(pDate) 
               AND A.AC_STATUS = 'ACT') 
          Fixed_Deposit_Count, 
       (SELECT COUNT (AC_ID) 
          FROM EMOB.MB_ACCOUNT_MST a, EMOB.ST_AGENT_POINT p 
         WHERE     A.POINT_ID = P.POINT_ID 
               AND SUBSTR (ac_No, 5, 1) = 5 
               AND p.POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', p.POINT_ID, 
                              pOutLet) 
               AND TRUNC(A.FINAL_CHECK_DATE) < TRUNC(pDate) 
               AND A.AC_STATUS = 'ACT') 
          DPS_TOTAL, 
      (SELECT COUNT (AC_ID) 
          FROM EMOB.MB_ACCOUNT_MST a, EMOB.ST_AGENT_POINT p 
         WHERE     A.POINT_ID = P.POINT_ID 
               AND SUBSTR (ac_No, 5, 1) = 5 
               AND p.POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', p.POINT_ID, 
                              pOutLet) 
               AND TRUNC(A.FINAL_CHECK_DATE) = TRUNC(pDate) 
               AND A.AC_STATUS = 'ACT') 
          dps_today, 
       (SELECT SUM (BALANCE) 
  FROM (SELECT SUM (BALANCE) BALANCE 
          FROM emob.mb_account_mst A, EMOB.MB_ACCOUNT_DAILY_BALANCE B 
         WHERE     point_id IS NULL 
               AND cust_no = 
                      DECODE ( 
                         pOutLet, 
                         'ALL', cust_no, 
                         (SELECT cust_no 
                            FROM EMOB.MB_CUSTOMER_MST a, 
                                 EMOB.ST_AGENT_POINT b 
                           WHERE     b.POINT_ID = pOutLet 
                                 AND a.CUST_TYPE = 'AGN' 
                                 AND a.CUST_NO = b.AGENT_ID 
                                 AND a.REVIEW_STATUS = 'A')) 
               AND A.AC_NO = B.ACCOUNT_NO 
        AND TO_CHAR (balance_date, 'DD-MM-YYYY') = 
                                        TO_CHAR (pDate - 1, 'DD-MM-YYYY') 
        UNION ALL 
        SELECT NVL (SUM (BALANCE), 0) BALANCE 
          FROM EMOB.MB_ACCOUNT_DAILY_BALANCE A, EMOB.MB_ACCOUNT_MST B 
         WHERE     TO_CHAR (balance_date, 'DD-MM-YYYY') = 
                      TO_CHAR (pDate - 1, 'DD-MM-YYYY') 
               AND A.ACCOUNT_NO = B.AC_NO 
               AND B.POINT_ID = 
                      DECODE ( pOutLet, 
                              'ALL', B.POINT_ID, 
                              pOutLet))) 
          deposit_trial_bal, 
       (SELECT COUNT (REQUEST_ID) 
          FROM EMOB.RM_PAYMENT_REQUEST 
         WHERE     TO_CHAR (request_date, 'dd-mm-yyyy') = 
                      TO_CHAR (pDate, 'DD-MM-YYYY') 
               AND AGENT_POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', AGENT_POINT_ID, 
                              pOutLet) 
               AND UPPER (VERIFY_FLAG) = 'P') 
          remit_qty, 
       (SELECT NVL (SUM (REQ_AMOUNT), 0) 
          FROM EMOB.RM_PAYMENT_REQUEST 
         WHERE     TO_CHAR (request_date, 'dd-mm-yyyy') = 
                      TO_CHAR (pDate, 'DD-MM-YYYY') 
               AND AGENT_POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', AGENT_POINT_ID, 
                              pOutLet) 
               AND UPPER (VERIFY_FLAG) = 'P') 
          remit_bal, 
       (SELECT NVL (SUM (TRAN_AMT_LC), 0) 
          FROM EMOB.MB_TRANSACTION_DTL 
         WHERE     TO_CHAR (CREATE_DATE, 'DD-MM-YYYY') = 
                      TO_CHAR (pDate, 'DD-MM-YYYY') 
               AND TRAN_CODE IN (SELECT TRAN_CODE 
                                   FROM EMOB.ST_TRANSACTION_CODE 
                                  WHERE NATURE_ID = 1)   /*GROUP BY DOC_DATE*/ 
             AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet)) 
          withdrawal_balance, 
       (SELECT COUNT (TRAN_AMT_LC) 
          FROM EMOB.MB_TRANSACTION_DTL 
         WHERE     TO_CHAR (CREATE_DATE, 'DD-MM-YYYY') = 
                      TO_CHAR (pDate, 'DD-MM-YYYY') 
               AND TRAN_CODE IN (SELECT TRAN_CODE 
                                   FROM EMOB.ST_TRANSACTION_CODE 
                                  WHERE NATURE_ID = 1)   /*GROUP BY DOC_DATE*/ 
            AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet)) 
          withdrawal_count, 
       (SELECT COUNT (LOG_ID) 
          FROM EMOB_AUDIT_LOG.AUD_USER_LOGIN_FAILED_LOG 
         WHERE     TO_CHAR (create_time, 'DD-MM-YYYY') = 
                      TO_CHAR (pDate, 'DD-MM-YYYY') 
               AND LOGIN_FAILED_CODE = 'IFN') 
          user_login_fp, 
       (  SELECT NVL (COUNT (POINT_ID), 0) 
            FROM st_agent_point 
           WHERE TRUNC(APPROVED_DATE) <= TRUNC(pDate) 
      AND LOCATION_TYPE = 'R' 
       AND NVL(STATUS,'N') = 'A') 
          tot_agent_rural, 
       (  SELECT NVL (COUNT (POINT_ID), 0) 
            FROM st_agent_point 
           WHERE  TRUNC(APPROVED_DATE) <= TRUNC(pDate) 
       AND LOCATION_TYPE = 'U' 
       AND NVL(STATUS,'N') = 'A') 
          tot_agent_urban, 
       (SELECT NVL (SUM (tran_amt_lc), 0) "Deposit Today" 
          FROM (SELECT SUM (tran_amt_lc) tran_amt_lc 
                    FROM EMOB.MB_TRANSACTION_DAILY 
                   WHERE     tran_code IN (09, 01, 08) 
                         AND TRUNC (create_date) = TRUNC (pDate) 
                AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet) 
                GROUP BY doc_num 
                UNION ALL 
                  SELECT SUM (tran_amt_lc) tran_amt_lc 
                    FROM EMOB.MB_TRANSACTION_dtl 
                   WHERE     tran_code IN (09, 01, 08) 
                         AND TRUNC (create_date) = TRUNC (pDate) 
                AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet) 
                GROUP BY doc_num)) 
          deposit_today, 
       (SELECT NVL (SUM (tran_amt_lc), 0) "Fund Transfer Amount" 
          FROM (  SELECT SUM (tran_amt_lc) tran_amt_lc 
                    FROM EMOB.MB_TRANSACTION_DAILY 
                   WHERE     tran_code IN (03, 13, 21) 
                         AND TRUNC (create_date) = TRUNC (pDate) 
                AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet) 
                GROUP BY doc_num 
                UNION ALL 
                  SELECT SUM (tran_amt_lc) tran_amt_lc 
                    FROM EMOB.MB_TRANSACTION_dtl 
                   WHERE     tran_code IN (03, 13, 21) 
                         AND TRUNC (create_date) = TRUNC (pDate) 
                AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet) 
                GROUP BY doc_num)) 
          fund_transfer_amt, 
       (SELECT COUNT (tran_id) "FUnd Transfer Number" 
          FROM (  SELECT COUNT (tran_id) tran_id 
                    FROM EMOB.MB_TRANSACTION_DAILY 
                   WHERE     tran_code IN (03, 13, 21) 
                         AND TRUNC (create_date) = TRUNC (pDate) 
                AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet) 
                GROUP BY doc_num 
                UNION ALL 
                  SELECT COUNT (tran_id) tran_id 
                    FROM EMOB.MB_TRANSACTION_dtl 
                   WHERE     tran_code IN (03, 13, 21) 
                         AND TRUNC (create_date) = TRUNC (pDate) 
                AND TRAN_POINT_ID=DECODE(pOutLet,'ALL',TRAN_POINT_ID,pOutLet) 
                GROUP BY doc_num)) 
          fund_transfer_num, 
       (SELECT NVL (SUM (AMOUNT), 0) "eft rtgs aMOUNT" 
          FROM (SELECT SUM (request_amount) AMOUNT 
                  FROM EMOB.MB_EFT_REQUEST 
                 WHERE     TRUNC (create_date) = TRUNC (pDate) 
                       AND POINT_ID = 
                              DECODE (pOutLet, 
                                      'ALL', POINT_ID, 
                                      pOutLet) 
                UNION ALL 
                SELECT SUM (REQUEST_AMOUNT) AMOUNT 
                  FROM EMOB.MB_RTGS_REQUEST 
                 WHERE     TRUNC (create_date) = TRUNC (pDate) 
                       AND POINT_ID = 
                              DECODE (pOutLet, 
                                      'ALL', POINT_ID, 
                                      pOutLet))) 
          EFT_RTGS_AMT, 
       (SELECT SUM (TOTAL) 
          FROM (SELECT COUNT (REQUEST_ID) TOTAL 
                  FROM EMOB.MB_EFT_REQUEST 
                 WHERE     TRUNC (create_date) = TRUNC (pDate) 
                       AND POINT_ID = 
                              DECODE (pOutLet, 
                                      'ALL', POINT_ID, 
                                      pOutLet) 
                UNION ALL 
                SELECT COUNT (REQUEST_ID) TOTAL 
                  FROM EMOB.MB_RTGS_REQUEST 
                 WHERE     TRUNC (create_date) = TRUNC (pDate) 
                       AND POINT_ID = 
                              DECODE (pOutLet, 
                                      'ALL', POINT_ID, 
                                      pOutLet))) 
          EFT_RTGS_COUNT, 
       (SELECT COUNT (COLL_ID) 
          FROM EMOB.UTL_BILL_COLLECTION 
         WHERE     COMP_ID = 11 
               AND TRUNC (CREATE_DATE) = TRUNC (pDate) 
               AND POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', POINT_ID, 
                              pOutLet)) 
          REB_Bill_Number, 
       (SELECT NVL (SUM (DUE_AMOUNT), 0) 
          FROM EMOB.UTL_BILL_COLLECTION 
         WHERE     COMP_ID = 11 
               AND TRUNC (CREATE_DATE) = TRUNC (pDate) 
               AND POINT_ID = 
                      DECODE (pOutLet, 
                              'ALL', POINT_ID, 
                              pOutLet)) 
          REB_Bill_Amount, 
          (SELECT COUNT (DISTINCT USER_ID) 
   FROM GUMS.MB_USER_LOG_WEB 
  WHERE TRUNC (IN_TIME) = TRUNC (pDate)) 
 Number_Of_Active_User , 
    (SELECT COUNT(AC_ID) FROM EMOB.MB_ACCOUNT_MST WHERE INI_CHECK_BY IS NULL 
    AND POINT_ID=DECODE(pOutLet,'ALL',POINT_ID,V('AI_AGENT_POINT_ID')) ) AT_POINT, 
    (SELECT COUNT(AC_ID) FROM EMOB.MB_ACCOUNT_MST WHERE FINAL_CHECK_BY IS NULL 
    AND POINT_ID=DECODE(pOutLet,'ALL',POINT_ID,V('AI_AGENT_POINT_ID'))) AT_ABD 
  FROM DUAL) --; 
loop 
   vContent:='<div class="row"> 
  <div class="column"> 
   <table> 
       <tr><th colspan="2" class="class1">CASA</th></tr> 
       <tr class="class2"><td style="width:50%;text-align: center;">Total</td><td style="width:50%;text-align: center;">Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.CASA_TOTAL 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.casa_today 
      || '</td></tr> 
      </table> 
  </div> 
  <div class="column"> 
   <table> 
       <tr><th colspan="2" class="class1">Fixed Deposit</th></tr> 
       <tr class="class2"><td style="width:50%;text-align: center;">Total</td><td style="width:50%;text-align: center;">Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.Fixed_dep_total 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.Fixed_Deposit_Count 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class1">DPS</th></tr> 
       <tr class="class2"><td style="width:50%;text-align: center;">Total</td><td style="width:50%;text-align: center;">Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.DPS_TOTAL 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.dps_today 
      || '</td></tr> 
   </table> 
  </div> 
</div> 
   <br /> 
<div class="row"> 
  <div class="column"> 
   <table> 
       <tr><th colspan="2" class="class4">Deposit</th></tr> 
       <tr class="class5"><td style="width:50%;text-align: center;">Trial Balance</td><td style="width:50%;text-align: center;">Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.deposit_trial_bal 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.deposit_today 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class4">Withdrawal</th></tr> 
       <tr class="class5"><td style="width:50%;text-align: center;">Number</td><td style="width:50%;text-align: center;">Amount Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.withdrawal_count 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.withdrawal_balance 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
   <table> 
       <tr><th colspan="2" class="class4">Fund Transfer</th></tr> 
       <tr class="class5"><td style="width:50%;text-align: center;">Number</td><td style="width:50%;text-align: center;">Amount Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.fund_transfer_num 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.fund_transfer_amt 
      || '</td></tr> 
   </table> 
  </div> 
</div> 
 <br /> 
<div class="row"> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class4">EFTN/RTGS</th></tr> 
       <tr class="class5"><td style="width:50%;text-align: center;">Number</td><td style="width:50%;text-align: center;">Amount Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.EFT_RTGS_COUNT 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.EFT_RTGS_AMT 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
   <table> 
       <tr><th colspan="2" class="class4">Foreign Remittance</th></tr> 
       <tr class="class5"><td style="width:50%;text-align: center;">Number</td><td style="width:50%;text-align: center;">Amount Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.remit_qty 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.remit_bal 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class4">REB-PBS BILL</th></tr> 
       <tr class="class5"><td style="width:50%;text-align: center;">Number</td><td style="width:50%;text-align: center;">Amount Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.REB_Bill_Number 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.REB_Bill_amount 
      || '</td></tr> 
   </table> 
  </div> 
</div> 
  <br /> 
<div class="row"> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class6">Debit Card</th></tr> 
       <tr class="class7"><td style="width:50%;text-align: center;">Total</td><td style="width:50%;text-align: center;">Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || 0 
      || '</td><td style="width:50%;text-align: center;">' 
      || 0 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class6">Cheque Clearing</th></tr> 
       <tr class="class7"><td style="width:50%;text-align: center;">Number</td><td style="width:50%;text-align: center;">Amount</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || 0 
      || '</td><td style="width:50%;text-align: center;">' 
      || 0 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
  <table> 
       <tr><th colspan="2" class="class6">Service Request</th></tr> 
       <tr class="class7"><td style="width:50%;text-align: center;">Pending</td><td style="width:50%;text-align: center;">Req. Today</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || 0 
      || '</td><td style="width:50%;text-align: center;">' 
      || 0 
      || '</td></tr> 
   </table> 
  </div> 
</div> 
<br /> 
<div class="row"> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class8">Total Agent Outlet</th></tr> 
       <tr class="class9"><td style="width:50%;text-align: center;">Rural</td><td style="width:50%;text-align: center;">Urban</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.tot_agent_rural 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.tot_agent_urban 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
   <table> 
       <tr><th colspan="2" class="class8">User/Login Today</th></tr> 
       <tr class="class9"><td style="width:50%;text-align: center;">Active</td><td style="width:50%;text-align: center;">FP Failed</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.Number_Of_Active_User 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.user_login_fp 
      || '</td></tr> 
   </table> 
  </div> 
  <div class="column"> 
    <table> 
       <tr><th colspan="2" class="class8">Account in Progress</th></tr> 
       <tr class="class9"><td style="width:50%;text-align: center;">At Outlet</td><td style="width:50%;text-align: center;">At ABD</td></tr> 
       <tr class="class3"><td style="width:50%;text-align: center;">' 
      || i.AT_POINT 
      || '</td><td style="width:50%;text-align: center;">' 
      || i.AT_ABD 
      || '</td></tr> 
   </table> 
  </div> 
</div>'; 
end loop; 
RETURN vContent;
END;
/
