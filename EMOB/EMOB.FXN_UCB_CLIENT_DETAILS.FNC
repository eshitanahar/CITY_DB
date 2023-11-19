CREATE OR REPLACE function EMOB.fxn_ucb_client_Details(br_in           IN NVARCHAR2,
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
SELECT sc.customer_no,
       sca.CCY ac_ccy,
       (select JOINT_HOLDER_DESCRIPTION
          from sttm_acc_joint_holder@flexuat x
         where x.CUST_AC_NO = sca.CUST_AC_NO
           AND ROWNUM < 2) JOINT_AC,
       case
         when CUSTOMER_TYPE = 'I' then
          UDF_4
         else
          (select FIELD_VAL_7
             from CSTM_FUNCTION_USERDEF_FIELDS@flexuat
            WHERE FUNCTION_ID = 'STDCIF'
              AND REC_KEY = sc.customer_no || '~')
       end Father_name,
       sca.AC_DESC full_name,
       sc.customer_type,
       to_char(sca.AC_OPEN_DATE, 'dd-MM-yyyy') AC_OPEN_DATE,
       sca.ADDRESS1 address_line1,
       sca.ADDRESS2 address_line2,
       sca.ADDRESS3 address_line3,
       sca.ADDRESS4 address_line4,
       '' AS auth_stat,
       sc.local_branch,
       sca.cust_ac_no,
       
       case
         when ACCOUNT_CLASS = 'SPRFCA' then
          'SME Private FC Account'
         else
          decode(substr(CUST_AC_NO, 5, 1),
                 '1',
                 'Current',
                 '2',
                 'Savings',
                 '3',
                 'SND',
                 '4',
                 'TD',
                 '5',
                 'RD',
                 '7',
                 'OD/CC',
                 'Other')
       end as ACCOUNT_TYPE,
       to_char(sca.PREVIOUS_STATEMENT_DATE, 'dd-MM-yyyy') PREVIOUS_STATEMENT_DATE,
       SB.BRANCH_NAME,
       (select nvl2(TELEPHONE, 'T:' || TELEPHONE, '') ||
               nvl2(MOBILE_NUMBER, ' M:' || MOBILE_NUMBER, '') ||
               nvl2(HOME_TEL_NO, ' H:' || HOME_TEL_NO, '')
          from STTM_CUST_PERSONAL@flexuat
         where CUSTOMER_NO = sc.customer_no) as Telephone,
       sca.ALT_AC_NO OldACNO,
       (select DESCRIPTION from STTM_LOCATION@flexuat t where LOC_CODE = LOCATION) CITY
  FROM sttm_cust_account@flexuat sca, sttm_customer@flexuat sc, sttm_branch@flexuat sb
 WHERE sc.customer_no = sca.cust_no(+)
   and SCA.BRANCH_CODE = sb.BRANCH_CODE
   and sb.branch_code = br_in
   and SUBSTR(SCA.CUST_AC_NO, 5, 1) not in ('4', '5')
   AND SCA.CUST_AC_NO = ac_no_in;
        
   

   RETURN o_cursor;
   
end fxn_ucb_client_Details;
/
