CREATE OR REPLACE function EMOB.fxn_ucb_client_state_hist(br_in      IN NVARCHAR2,
                                                     ac_no_in   IN NVARCHAR2,
                                                     from_dt_in in date,
                                                     to_dt_in   in date)
  RETURN SYS_REFCURSOR as

  -- ********************************************************************************
  -- CREATE DATE: 07/12/2017
  -- AUTHOR:      Tariqul Ismail
  -- DESIG:       AVP
  -- PURPOSE:     GETS ALL THE RECORDS FOR REPORT.
  -- ********************************************************************************

  o_cursor SYS_REFCURSOR;

BEGIN

  OPEN o_cursor FOR
    SELECT tt.*,
           SUM(tt.LCY_AMOUNT) OVER(ORDER BY nvl(tt.VALUE_DT2, sysdate - 100000), TT.AC_ENTRY_SR_NO ROWS UNBOUNDED PRECEDING) BALANCE,
           
           (SELECT ADDL_TEXT
               FROM cstb_addl_text@flexuat x
              WHERE REFERENCE_NO = tt.TRN_REF_NO
                and x.EVNT_SEQ_NO = tt.EVENT_SR_NO
                and rownum < 2) ||
            (select NARRATIVE
               from detb_rtl_teller@flexuat
              where TRN_REF_NO = tt.TRN_REF_NO) ||
            (select FIELD_VAL_1
               from CSTM_CONTRACT_USERDEF_FIELDS@flexuat
              WHERE MODULE = 'FT'
                and CONTRACT_REF_NO = tt.TRN_REF_NO
                and rownum < 2) || (case
              when substr(tt.TRN_REF_NO, 4, 4) in ('OCTM', 'OCTI') then
               (select ULT_BENEFICIARY1 || ', ' || ULT_BENEFICIARY2 narration
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
            end) || '    ' || (select USER_REF_NO
                                 from cstb_contract@flexuat
                                where CONTRACT_REF_NO = tt.TRN_REF_NO
                                  AND ROWNUM >= 1)
           /*||case when tt.module1='CL' then nvl2(tt.RELATED_ACCOUNT,' Related Account: ','')||tt.RELATED_ACCOUNT 
           ||' , '||(select AMOUNT_DESC   from UCB_AMOUNT_DESC@ucbprod_dbl x where  x.amount_tag=tt.amount_tag) end*/
           
            || nvl2(tt.RELATED_ACCOUNT, ' Related Account: ', '') ||
            tt.RELATED_ACCOUNT || '' /*case
                                                     when tt.module1 = 'CL' then
                                                      (select AMOUNT_DESC
                                                         from UCB_AMOUNT_DESC@ucbprod_dbl x
                                                        where x.amount_tag = tt.amount_tag)
                                                   end */
            || '' || (select remarks
                        from xptb_contract_master@flexuat z
                       where z.contract_ref_no = tt.TRN_REF_NO
                         and rownum < 2) || '' ||
            (select b.clg_bank_name || ', ' || a.branch_desc BRANCH
               from detm_clg_brn_code@flexuat a, detm_clg_bank_code@flexuat b
              where a.bank_code = b.clg_bank_code
                and a.bank_code || a.sector_code || a.branch_code =
                    (select ROUTING_NO
                       from cstb_clearing_master@flexuat
                      where reference_no = tt.TRN_REF_NO
                        and tt.amount_tag != 'CHG_AMT1')) --For Clearing info
           
            NARRATION
    
      FROM ((select '0' AC_BRANCH,
                    'Balance Forward' AC_NO,
                    null TRN_DT,
                    null VALUE_DT,
                    NULL VALUE_DT2,
                    0 AC_ENTRY_SR_NO, --DRCR_IND,     LCY_AMOUNT,  
                    Null EVENT_SR_NO,
                    '' DRCR_IND,
                    sum(CASE
                          WHEN s.DRCR_IND = 'C' THEN
                           decode(s.AC_CCY, 'BDT', s.LCY_AMOUNT, s.FCY_AMOUNT)
                          else
                           -decode(s.AC_CCY, 'BDT', s.LCY_AMOUNT, s.FCY_AMOUNT)
                        END) LCY_AMOUNT,
                    '' ac_ccy,
                    '' trn_code,
                    '' trn_ref_no,
                    '' related_account,
                    0 DEBIT,
                    0 CREDIT,
                    '' MODULE1,
                    '' AS CheckNo,
                    0 as ENTRY_SEQ_NO,
                    NULL amount_tag
               FROM ACVW_ALL_AC_ENTRIES@flexuat s
              WHERE s.VALUE_DT < from_dt_in
                and SUBSTR(AC_NO, 5, 1) not in ('4', '5')
                and AC_NO = ac_no_in
                and s.ac_branch = br_in
             
             ) UNION SELECT t.AC_BRANCH, '' AC_NO,
            to_char(t.TRN_DT, 'dd-MM-yyyy') TRN_DT,
            to_char(t.VALUE_DT, 'dd-MM-yyyy') VALUE_DT, t.VALUE_DT,
            t.AC_ENTRY_SR_NO, t.EVENT_SR_NO, t.DRCR_IND, (CASE
              WHEN DRCR_IND = 'D' THEN
               decode(t.AC_CCY, 'BDT', t.LCY_AMOUNT, t.FCY_AMOUNT) * (-1)
              ELSE
               decode(t.AC_CCY, 'BDT', t.LCY_AMOUNT, t.FCY_AMOUNT)
            END) LCY_AMOUNT, t.ac_ccy,
            s.TRN_DESC || ' ' ||
            (select BRN
               from iftb_extpc_log@flexuat
              where trn_ref_no = t.TRN_REF_NO) TRN_DESC, t.trn_ref_no,
            related_account,
            DECODE(t.drcr_ind,
                   'D',
                   decode(t.AC_CCY, 'BDT', t.LCY_AMOUNT, t.FCY_AMOUNT),
                   0) AS DEBIT,
            DECODE(t.drcr_ind,
                   'C',
                   decode(t.AC_CCY, 'BDT', t.LCY_AMOUNT, t.FCY_AMOUNT),
                   0) AS CREDIT, MODULE, t.INSTRUMENT_CODE AS CheckNo,
            t.ENTRY_SEQ_NO, t.amount_tag FROM ACVW_ALL_AC_ENTRIES@flexuat t,
            sttm_trn_code@flexuat s WHERE
            T.TRN_CODE = S.TRN_CODE and t.AUTH_STAT = 'A' and
            length(t.AC_NO) <> 9 and SUBSTR(t.AC_NO, 5, 1) not in ('4', '5') and
            t.AC_NO = ac_no_in and t.ac_branch = br_in
           
            AND t.VALUE_DT BETWEEN from_dt_in AND to_dt_in) tt,
           DETB_RTL_TELLER@flexuat d
     WHERE tt.TRN_REF_NO = d.TRN_REF_NO(+);
    
     RETURN o_cursor;

END fxn_ucb_client_state_hist;
/
