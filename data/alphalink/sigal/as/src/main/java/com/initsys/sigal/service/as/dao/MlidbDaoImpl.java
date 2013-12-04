package com.initsys.sigal.service.as.dao;

import java.util.List;

import javax.sql.DataSource;

import org.springframework.jdbc.core.simple.ParameterizedBeanPropertyRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.initsys.sigal.protocol.Sigal.MlidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.MlidbUpdateRequest;
import com.initsys.sigal.service.as.MlidbEntry;

public class MlidbDaoImpl implements MlidbDao {
    private SimpleJdbcTemplate template;

    protected SimpleJdbcTemplate getTemplate() {
        return template;
    }

    public void setDataSource(DataSource source) {
        setTemplate(new SimpleJdbcTemplate(source));
    }

    private void setTemplate(SimpleJdbcTemplate template) {
        this.template = template;
    }

    /**
     * @see com.initsys.sigal.service.as.dao.MlidbDao#updateDatabase(com.initsys.sigal.protocol
     *      .Sigal.MlidbUpdateRequest)
     */
    public int updateDatabase(MlidbUpdateRequest request) {
        final int nb = getTemplate()
                .update(
                        "insert into "
                                + "mobile_line_information (account_code, "
                                + "  msisdn, carrier_code "
                                + ") values (?, ?, ?) "
                                + "on duplicate key update "
                                + "  account_code = values(account_code),"
                                + "  msisdn = values(msisdn),"
                                + "  carrier_code = values(carrier_code) ",
                        request.getAccountCode(),
                        request.getMsisdn(),
                        request.getCarrierCode());
        return nb;
    }

    /**
     * @see com.initsys.sigal.service.as.MlidbDao#queryDbByMsisdn(com.initsys.sigal
     *      .protocol.Sigal.MlidbQueryRequest)
     */
    public List<MlidbEntry> queryDbByMsisdn(MlidbQueryRequest mlidbQuery) {
        List<MlidbEntry> list;
        list = getTemplate()
                .query(
                        "select "
                                + "mli.account_code, "
                                + "mli.msisdn, "
                                + "mli.carrier_code "
                                + "from mobile_line_information mli where mli.msisdn = ?",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(MlidbEntry.class),
                        mlidbQuery.getMsisdn());
        return list;
    }

}
