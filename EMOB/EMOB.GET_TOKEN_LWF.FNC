CREATE OR REPLACE FUNCTION EMOB.get_token_lwf
   RETURN VARCHAR2
AS
   l_clob   CLOB;
   v_body   VARCHAR2 (1024);
   vToken   VARCHAR2 (32000);
BEGIN
   v_body := '{
"username":"abs",
"password":"Agent@5731"
}'  ;

   APEX_WEB_SERVICE.g_request_headers (1).name := 'Content-Type';
   APEX_WEB_SERVICE.g_request_headers (1).VALUE := 'application/json';
   l_clob :=
      APEX_WEB_SERVICE.make_rest_request (
         p_url           => 'https://workflow.thecitybank.com/citybank/intgr/external/api/getBearerToken',
         p_http_method   => 'POST',
         p_body          => v_body,
         p_transfer_timeout =>10,
         p_wallet_path   => 'file:/u01/lwf_wallets',
         p_wallet_pwd    => 'City1234#');
   vToken := to_char(l_clob); -- AS VARCHAR2 (1024);
   RETURN vToken;
END;
/
