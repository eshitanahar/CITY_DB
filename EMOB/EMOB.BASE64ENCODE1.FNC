CREATE OR REPLACE function EMOB.base64encode1
    ( i_blob                        in blob)
    return clob
is
    l_step                          pls_integer := 22500; -- make sure you set a multiple of 3 not higher than 24573
    l_converted                     varchar2(32767);

    l_buffer_size_approx            pls_integer := 1048576;
    l_buffer                        clob;
    io_clob                         clob;
begin
    dbms_lob.createtemporary(l_buffer, true, dbms_lob.call);

    for i in 0 .. trunc((dbms_lob.getlength(i_blob) - 1 )/l_step) loop
        l_converted := utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_lob.substr(i_blob, l_step, i * l_step + 1)));
        dbms_lob.writeappend(l_buffer, length(l_converted), l_converted);

        if dbms_lob.getlength(l_buffer) >= l_buffer_size_approx then
            dbms_lob.append(io_clob, l_buffer);
            dbms_lob.trim(l_buffer, 0);
        end if;
    end loop;

    dbms_lob.append(io_clob, l_buffer);

    dbms_lob.freetemporary(l_buffer);
    return io_clob;
end;
/
