package com.initsys.sigal.service.as.dao;

import java.util.List;

import javax.sql.DataSource;

import org.springframework.jdbc.core.simple.ParameterizedBeanPropertyRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.initsys.sigal.protocol.Sigal.NpdbQueryRequest;
import com.initsys.sigal.service.as.NpdbEntry;

public class NpdbDaoImpl implements NpdbDao {
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
     * @see com.initsys.sigal.service.as.dao.NpdbDao#query(com.initsys.sigal.protocol.Sigal.NpdbQueryRequest)
     */
    public List<NpdbEntry> query(NpdbQueryRequest request) {
        List<NpdbEntry> list = getTemplate()
                .query(
                        "select number, portability_prefix as prefix from number "
                                + "where number = ?",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(NpdbEntry.class),
                        request.getNumber());
        return list;
    }
}
