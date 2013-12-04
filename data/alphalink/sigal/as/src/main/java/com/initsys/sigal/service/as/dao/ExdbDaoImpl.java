package com.initsys.sigal.service.as.dao;

import java.util.List;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.ParameterizedBeanPropertyRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.initsys.sigal.protocol.Sigal.ExdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.ExdbUpdateRequest;
import com.initsys.sigal.service.as.ExdbEntry;

public class ExdbDaoImpl implements ExdbDao {
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

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.initsys.sigal.service.as.ExdbDao#updateDatabase(com.initsys.sigal
     * .protocol.Sigal.ExdbUpdateRequest)
     */
    public int updateDatabase(final ExdbUpdateRequest request) {
        int nb = getTemplate()
                .update(
                        "insert into "
                                + "exchange_information (account_code, "
                                + "  subscriber_number, inbound_numbering_plan, "
                                + "  max_calls, max_inbound_calls,"
                                + "  max_outbound_calls, outbound_numbering_plan "
                                + "  locked, carrier_code "
                                + ") values (?, ?, ?, ?, ?, ?, ?, ?, ?) "
                                + "on duplicate key update "
                                + "  subscriber_number = values(subscriber_number),"
                                + "  inbound_numbering_plan = values(inbound_numbering_plan),"
                                + "  max_calls = values(max_calls),"
                                + "  max_inbound_calls = values(max_inbound_calls),"
                                + "  max_outbound_calls = values(max_outbound_calls),"
                                + "  outbound_numbering_plan = values(outbound_numbering_plan),"
                                + "  locked = values(locked),"
                                + "  carrier_code = values(carrier_code) ",
                        request.getAccountCode(),
                        request.getSubscriberNumber(),
                        request.getInboundNumberingPlan(),
                        request.getMaxCalls(), request.getMaxInboundCalls(),
                        request.getMaxOutboundCalls(),
                        request.getOutboundNumberingPlan(),
                        request.getLocked() ? "1" : "0",
                        request.getCarrierCode());
        return nb;
    }

    public List<ExdbEntry> queryByAccountCode(ExdbQueryRequest exdbQuery) {
        List<ExdbEntry> list;
        list = getTemplate()
                .query(
                        "select "
                                + "ei.account_code, "
                                + "ei.subscriber_number, "
                                + "ei.max_inbound_calls, "
                                + "ei.max_outbound_calls, "
                                + "ei.max_calls, "
                                + "ei.inbound_numbering_plan, "
                                + "ei.outbound_numbering_plan, "
                                + "ei.locked, "
                                + "ei.carrier_code, "
                                + "ei.weird_identity "
                                + "from exchange_information ei where ei.account_code = ?",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(ExdbEntry.class),
                        exdbQuery.getAccountCode());
        return list;
    }
}
