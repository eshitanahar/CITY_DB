CREATE OR REPLACE FUNCTION EMOB.custom_auth1 (p_username   IN VARCHAR2,
                                              p_password   IN VARCHAR2)
   RETURN BOOLEAN
IS
   vCheckStatus        VARCHAR2 (1024);
   vUserSts            VARCHAR2 (1024);
   vUserType           VARCHAR2 (1024);
   vPwdDate            DATE;
   vUserPwd            VARCHAR2 (1024);
   VInvLoginCnt        NUMBER;
   vRestrictFromDt     DATE;
   vRestrictToDt       DATE;
   vOutPassword        VARCHAR2 (1024);
   vMaxInvLoginAllow   NUMBER := 0;

   outpass             VARCHAR2 (20);
   vSysdate            DATE := TO_DATE (SYSDATE, 'DD/MM/RRRR');
   vtodays             NUMBER (3);
   vFingerPrint        VARCHAR2 (1);
   vCount              NUMBER := 0;
   out_migflg          VARCHAR2 (1);
BEGIN
   --- User Check -------------------

   BEGIN
      IF p_username IS NULL
      THEN
         raise_application_error (-20001, 'User Id Cannot be Blank.');
      END IF;

      /*IF LENGTH (RTRIM (p_username)) NOT IN (8)
      THEN
         raise_application_error (-20002, 'User Id should be eight characters of length.');
      END IF;*/

      BEGIN
         SELECT CHECK_STATUS,
                USER_STS,
                USER_TYPE,
                PWD_DATE,
                USER_PWD,
                INV_LOGIN_CNT,
                RESTRICT_FROM_DT,
                RESTRICT_TO_DT,
                FINGER_PRINT
           INTO vCheckStatus,
                vUserSts,
                vUserType,
                vPwdDate,
                vUserPwd,
                VInvLoginCnt,
                vRestrictFromDt,
                vRestrictToDt,
                vFingerPrint
           FROM MB_USER_MST
          WHERE UPPER (USER_CODE) = UPPER (p_username);


         IF vCheckStatus = 'N'
         THEN
            raise_application_error (
               -20003,
               'Waiting for Approval. Conatct With Adminstrator.');
         END IF;

         IF vCheckStatus = 'E'
         THEN
            raise_application_error (-20003, 'User is Expired.');
         END IF;

         IF vCheckStatus = 'S'
         THEN
            raise_application_error (-20003, 'User is Suspend.');
         END IF;

         IF vCheckStatus = 'T'
         THEN
            raise_application_error (
               -20003,
               'User is Temporary Suspend. Please Try After 10 Minutes.');
         END IF;

         IF TRUNC (SYSDATE) BETWEEN vRestrictFromDt AND vRestrictToDt
         THEN
            raise_application_error (-20003,
                                     'Today is Restricted For Your Login.');
         END IF;
      /*  IF NVL (vUserType, 'X') != 'L'
        THEN
           raise_application_error (-20006,'You are not a Login User...,Inform the System Administrator to check the User Type for your Userid');
        END IF;*/

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            raise_application_error (-20003, 'Invalid User...');
         WHEN TOO_MANY_ROWS
         THEN
            raise_application_error (-20003, 'User Not Valid.');
      END;
   END;

   IF vCheckStatus = 'A'
   THEN
      BEGIN
         SELECT MAX_INV_LOGIN INTO vMaxInvLoginAllow FROM mb_global_rule;
      END;

      IF NVL (vInvLoginCnt, 0) > vMaxInvLoginAllow
      THEN
         raise_application_error (
            -20003,
            'Login Denied., Exceeded the Max. No. of Invalid Try.');
      END IF;


      -- Password check
      ------------------------
      IF vFingerPrint = 'N'
      THEN
        if p_password is null then 
          raise_application_error (-20003, 'Please Enter Your Password.'); 
        end if;
        
         BEGIN
            SELECT dfn_create_password_encrypted (p_username, p_password)
              INTO vOutPassword
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               raise_application_error (-20003, 'Authorization Check Error.');
         END;

         IF NVL (vOutPassword, 'x') <> NVL (vUserPwd, 'y')
         THEN
            BEGIN
               UPDATE MB_USER_MST
                  SET INV_LOGIN_CNT = NVL (INV_LOGIN_CNT, 0) + 1,
                      USER_STS = 'T'
                WHERE UPPER (USER_CODE) LIKE UPPER (p_username);
            END;

            IF SQL%ROWCOUNT != 1
            THEN
               raise_application_error (
                  -20004,
                  'Problem Found.Contact With Administrator');
            END IF;
            raise_application_error (-20004,'Incorrect Password.'||vOutPassword||'  '||vUserPwd);
            RETURN FALSE;
         ELSE
            BEGIN
               UPDATE MB_USER_MST
                  SET LAST_LOGIN = SYSDATE,
                      LOGIN_CNT = NVL (LOGIN_CNT, 0) + 1
                WHERE UPPER (USER_CODE) LIKE UPPER (p_username);
            END;

            IF SQL%ROWCOUNT = 1
            THEN
               COMMIT;
            ELSE
               raise_application_error (
                  -20005,
                  'Problem Found.Contact With Administrator');
            END IF;
            
            RETURN TRUE;
         END IF;
      ELSIF vFingerPrint = 'Y'
      THEN
         BEGIN
            SELECT COUNT (FINGER_STATUS)
              INTO vCount
              FROM FP_USER_LOGIN
             WHERE     USER_CODE = USER_CODE
                   AND SESSION_ID = v ('APP_SESSION')
                   AND LOGIN_STATUS = 'N'
                   AND CREATE_DATE = TRUNC (SYSDATE);

            IF vCount != 1
            THEN
               raise_application_error (-20005, 'Finger Print Not Found.');
            END IF;
         END;
      END IF;
   END IF;

   --END IF;

  /* BEGIN
      IF ADD_MONTHS (vPwdDate, 3) <= vSysdate
      THEN
         BEGIN
            UPDATE MB_USER_MST
               SET USER_STS = 'E', LOGON_PASS_CHANGE = 'Y'
             WHERE UPPER (USER_CODE) LIKE UPPER (p_username);
         END;

         IF SQL%ROWCOUNT = 1
         THEN
            COMMIT;
         ELSE
            raise_application_error (
               -20006,
               'Problem Found.Contact With Administrator');
         END IF;

         raise_application_error (
            -20001,
            'Your password has expired. Contact With Administrator.');
      END IF;

      RETURN TRUE;
   END;*/
END;
/
