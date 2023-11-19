CREATE OR REPLACE function EMOB.fxn_ucb_test(br_in      IN NVARCHAR2,
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
  
    select  t.trn_ref_no,
           t.related_account,
           DECODE(t.drcr_ind,
                  'D',
                  decode(t.AC_CCY, 'BDT', t.LCY_AMOUNT, t.FCY_AMOUNT),
                  0) AS DEBIT,
           DECODE(t.drcr_ind,
                  'C',
                  decode(t.AC_CCY, 'BDT', t.LCY_AMOUNT, t.FCY_AMOUNT),
                  0) AS CREDIT,
           MODULE,
           t.INSTRUMENT_CODE AS CheckNo,
           t.ENTRY_SEQ_NO,
           t.amount_tag
      FROM ACVW_ALL_AC_ENTRIES@flexuat t
     WHERE t.VALUE_DT BETWEEN from_dt_in AND to_dt_in
       and length(t.AC_NO) <> 9
       and SUBSTR(t.AC_NO, 5, 1) not in ('4', '5')
       and t.ac_branch = br_in
       and t.AC_NO = ac_no_in
       and t.AUTH_STAT = 'A' ;
       
       RETURN o_cursor;

END fxn_ucb_test;
/
