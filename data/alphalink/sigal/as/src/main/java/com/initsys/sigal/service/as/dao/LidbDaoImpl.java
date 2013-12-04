package com.initsys.sigal.service.as.dao;

import java.util.List;

import javax.sql.DataSource;

import org.springframework.jdbc.core.simple.ParameterizedBeanPropertyRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.initsys.sigal.protocol.Sigal.LidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.LidbUpdateRequest;
import com.initsys.sigal.service.as.LidbEntry;

public class LidbDaoImpl implements LidbDao {
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
     * @see com.initsys.sigal.service.as.dao.LidbDao#updateRecord(com.initsys.sigal.protocol
     *      .Sigal.LidbUpdateRequest)
     */
    public int updateRecord(LidbUpdateRequest request) {
        final int nb = getTemplate()
                .update(
                        "insert into "
                                + "number (number, redirect_to, presentation, insee_code, subscriber_number) "
                                + "  values (?, ?, ?, ?, ?) "
                                + "on duplicate key update "
                                + "  redirect_to = values(redirect_to),"
                                + "  presentation = values(presentation),"
                                + "  insee_code = values(insee_code), "
                                + "  subscriber_number = values(subscriber_number) ",
                        request.getNumber(),
                        request.hasRedirectTo() ? request.getRedirectTo()
                                : null, request.getPresentation(),
                        request.getInseeCode(), request.getSubscriberNumber());
        return nb;
    }

    /**
     * @see com.initsys.sigal.service.as.LidbDao#queryDbByAccountCode(com.initsys
     *      .sigal.protocol.Sigal.LidbQueryRequest)
     */
    public List<LidbEntry> queryDbByAccountCode(LidbQueryRequest lidbQuery) {
        List<LidbEntry> list;
        list = getTemplate()
                .query(
                        "select "
                                + "null as number, "
                                + "null as redirect_to, "
                                + "li.account_code, "
                                + "li.subscriber_number,    "
                                + "li.max_inbound_calls, "
                                + "li.max_outbound_calls, "
                                + "li.max_calls, "
                                + "li.inbound_numbering_plan, "
                                + "li.outbound_numbering_plan, "
                                + "li.locked,"
                                + "li.carrier_code,"
                                + "li.trunk, "
                                + "li.fixed_cid, "
                                + "li.indication, "
                                + "n.insee_code, "
                                + "null as fax, "
                                + "null as voicemail "
                                + "from line_information li join number n on (n.subscriber_number = li.subscriber_number) "
                                + "where n.subscriber_number = n.number and li.account_code = ?",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(LidbEntry.class),
                        lidbQuery.getAccountCode());
        return list;
    }

    /**
     * @see com.initsys.sigal.service.as.LidbDao#queryDbByNumber(com.initsys.sigal
     *      .protocol.Sigal.LidbQueryRequest)
     */
    public List<LidbEntry> queryDbByNumber(LidbQueryRequest lidbQuery) {
        List<LidbEntry> list;
        list = getTemplate()
                .query(
                        "select "
                                + "n.number, "
                                + "n.redirect_to, "
                                + "li.account_code, "
                                + "li.subscriber_number, "
                                + "li.max_inbound_calls,"
                                + "li.max_outbound_calls, "
                                + "li.max_calls, "
                                + "li.inbound_numbering_plan, "
                                + "li.outbound_numbering_plan, "
                                + "n.presentation, "
                                + "n.insee_code, "
                                + "li.locked,"
                                + "li.carrier_code, "
                                + "li.trunk,"
                                + "li.fixed_cid, "
                                + "li.indication, "
                                + "n.fax,"
                                + "n.voicemail "
                                + "from number n join line_information li on "
                                + "  (n.subscriber_number = li.subscriber_number) "
                                + "where n.number = ?",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(LidbEntry.class),
                        lidbQuery.getNumber());
        return list;
    }

}
