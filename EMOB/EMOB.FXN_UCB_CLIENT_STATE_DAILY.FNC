CREATE OR REPLACE function EMOB.fxn_ucb_client_state_Daily(br_in           IN NVARCHAR2,
                                                   ac_no_in        IN NVARCHAR2)
                                                   RETURN SYS_REFCURSOR 
                                                   as

  -- ********************************************************************************
  -- CREATE DATE: 07/12/2017
  -- AUTHOR:      Tariqul Ismail
  -- DESIG:       AVP
  -- PURPOSE:     GETS ALL THE RECORDS FOR REPORT.
  -- ********************************************************************************

  o_cursor   SYS_REFCURSOR;
  
BEGIN
  
   OPEN o_cursor FOR
   
    SELECT AC_BRANCH,
           AC_NO,
           TRN_DT,
           AC_ENTRY_SR_NO,
           EVENT_SR_NO,
           DRCR_IND,
           ACY_AMOUNT LCY_AMOUNT,
           AC_CCY,
           TRN_CODE,
           decode(Module1, 'RT', EXTERNAL_REF_NO, TRN_REF_NO) TRN_REF_NO,
           RELATED_ACCOUNT,
           DEBIT,
           CREDIT,
           MODULE1,
           CHECKNO,
           ENTRY_SEQ_NO,
           AMOUNT_TAG,
           SUM(tt.ACY_AMOUNT) OVER(ORDER BY TT.AC_ENTRY_SR_NO, tt.TRN_DT ROWS UNBOUNDED PRECEDING) BALANCE,
           
           nvl2(TRN_DT, 'Trn. Br: ', '') || substr(TRN_REF_NO, 1, 3) || ' ' || case
             when module1 in ('DE', 'RT') then
              (SELECT ADDL_TEXT
                 FROM cstb_addl_text@flexuat x
                WHERE REFERENCE_NO = tt.TRN_REF_NO
                  and x.EVNT_SEQ_NO = tt.EVENT_SR_NO
                  and rownum < 2)
           end || decode(module1,
                         'RT',
                         (select NARRATIVE
                            from detb_rtl_teller@flexuat
                           where TRN_REF_NO = tt.TRN_REF_NO)) ||
           (select FIELD_VAL_1
              from CSTM_CONTRACT_USERDEF_FIELDS@flexuat
             WHERE MODULE = 'FT'
               and CONTRACT_REF_NO = tt.TRN_REF_NO) ||
           (case
              when substr(tt.TRN_REF_NO, 4, 4) in ('OCTM', 'OCTI') then
               (select ULT_BENEFICIARY1 || ',' || ULT_BENEFICIARY2 narration
                  from FTTB_CONTRACT_MASTER@flexuat
                 WHERE PRODUCT_CODE IN ('OCTM', 'OCTI')
                   and CONTRACT_REF_NO = tt.TRN_REF_NO
                   AND rownum < 2)
              else
               null
            end) || (case
                       when substr(tt.TRN_REF_NO, 4, 4) in ('IFTM', 'IFTI') then
                        (select distinct DR_CCY || '' || DR_AMOUNt || '@' ||
                                         EXCHANGE_RATE narration
                           from FTTB_CONTRACT_MASTER@flexuat
                          WHERE PRODUCT_CODE IN ('IFTM', 'IFTI')
                            and CONTRACT_REF_NO = tt.TRN_REF_NO
                            AND rownum < 2)
                       else
                        null
                     end) || ' ' ||
           (select USER_REF_NO
              from cstb_contract@flexuat
             where CONTRACT_REF_NO = tt.TRN_REF_NO
               AND ROWNUM >= 1)
           
           || nvl2(tt.RELATED_ACCOUNT, ' Related Account: ', '') ||
           tt.RELATED_ACCOUNT || ''/*case
             when tt.module1 = 'CL' then
              (select AMOUNT_DESC
                 from UCB_AMOUNT_DESC@ucbprod_dbl x
                where x.amount_tag = tt.amount_tag)
           end */|| '' || (select remarks
                           from xptb_contract_master@flexuat z
                          where z.contract_ref_no = tt.TRN_REF_NO
                            and rownum < 2) || '' || case
             when module1 in ('CM', 'FT', 'CG') then
              (select b.clg_bank_name || ', ' || a.branch_desc BRANCH
                 from detm_clg_brn_code@flexuat a, detm_clg_bank_code@flexuat b
                where a.bank_code = b.clg_bank_code
                  and a.bank_code || a.sector_code || a.branch_code =
                      (select ROUTING_NO
                         from cstb_clearing_master@flexuat k
                        where reference_no = tt.TRN_REF_NO
                          AND k.TXN_DATE = trunc(sysdate)
                          and tt.amount_tag != 'CHG_AMT1'))
           end --For Clearing info
           
           NARRATION
    
      FROM ((select '0' AC_BRANCH,
                    'Balance Forward' AC_NO,
                    null TRN_DT,
                    0 AC_ENTRY_SR_NO, --DRCR_IND,     LCY_AMOUNT,  
                    Null EVENT_SR_NO,
                    '' DRCR_IND,
                    ACY_OPENING_BAL ACY_AMOUNT,
                    '' ac_ccy,
                    '' trn_code,
                    '' trn_ref_no,
                    '' related_account,
                    0 DEBIT,
                    0 CREDIT,
                    '' MODULE1,
                    '' AS CheckNo,
                    0 as ENTRY_SEQ_NO,
                    NULL amount_tag,
                    Null EXTERNAL_REF_NO
               FROM sttm_cust_account@flexuat s
              WHERE CUST_AC_NO = ac_no_in
                and SUBSTR(CUST_AC_NO, 5, 1) not in ('4', '5')
                and BRANCH_CODE = br_in) UNION SELECT t.AC_BRANCH, '' AC_NO,
            to_char(t.TRN_DT, 'dd-MM-yyyy') TRN_DT, t.AC_ENTRY_SR_NO,
            t.EVENT_SR_NO, t.DRCR_IND, (CASE
              WHEN DRCR_IND = 'D' THEN
               decode(t.AC_CCY,
                      decode(ac_branch, '999', 'USD', 'BDT'),
                      t.LCY_AMOUNT,
                      t.FCY_AMOUNT) * (-1)
              ELSE
               decode(t.AC_CCY,
                      decode(ac_branch, '999', 'USD', 'BDT'),
                      t.LCY_AMOUNT,
                      t.FCY_AMOUNT)
            END) LCY_AMOUNT, t.ac_ccy,
            s.TRN_DESC || ' ' ||
            decode(MODULE,
                   'RT',
                   (select BRN
                      from iftb_extpc_log@flexuat
                     where trn_ref_no = t.TRN_REF_NO)) TRN_DESC,
            t.trn_ref_no, related_account,
            DECODE(t.drcr_ind,
                   'D',
                   decode(t.AC_CCY,
                          decode(ac_branch, '999', 'USD', 'BDT'),
                          t.LCY_AMOUNT,
                          t.FCY_AMOUNT),
                   0) AS DEBIT,
            DECODE(t.drcr_ind,
                   'C',
                   decode(t.AC_CCY,
                          decode(ac_branch, '999', 'USD', 'BDT'),
                          t.LCY_AMOUNT,
                          t.FCY_AMOUNT),
                   0) AS CREDIT, MODULE, t.INSTRUMENT_CODE AS CheckNo,
            t.ENTRY_SEQ_NO, t.amount_tag, t.EXTERNAL_REF_NO FROM
            actb_daily_log@flexuat t, sttm_trn_code@flexuat s WHERE
            T.TRN_CODE = S.TRN_CODE AND
            t.TRN_DT =
            (select today from sttm_dates@flexuat where branch_code = '000') and
            CUST_GL = 'A' and DELETE_STAT <> 'D' and t.AUTH_STAT = 'A' and
            SUBSTR(t.AC_NO, 5, 1) not in ('4', '5') and t.AC_NO = ac_no_in and
            t.ac_branch = br_in) tt;


   RETURN o_cursor;
   
END fxn_ucb_client_state_Daily;
/
