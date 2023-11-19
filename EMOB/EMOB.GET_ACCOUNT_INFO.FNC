CREATE OR REPLACE function EMOB.get_account_info (p_acc_no in varchar2)
return varchar2
is
   v_branch_code  varchar2(150);
   v_ac_title          varchar2(100);
   v_initial_amt     varchar2(20);
   
BEGIN
        SELECT BRANCH_CODE,AC_TITLE,INITIAL_AMT 
        into v_branch_code,v_ac_title,v_initial_amt
        FROM MB_ACCOUNT_MST
        WHERE AC_NO = p_acc_no;
        
        v_branch_code := v_branch_code||' - '||v_ac_title|| ' - '||v_initial_amt ;
        RETURN v_branch_code;
EXCEPTION
       When no_data_found then
             raise_application_error(-20001,'No Data Found For this Account');   
       When too_many_rows then
             raise_application_error(-20002,'Multiple Data Found For this Account');  
END;
/
