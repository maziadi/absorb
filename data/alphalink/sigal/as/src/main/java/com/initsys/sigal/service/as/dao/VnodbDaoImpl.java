package com.initsys.sigal.service.as.dao;

import java.util.List;

import javax.sql.DataSource;

import org.springframework.jdbc.core.simple.ParameterizedBeanPropertyRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.initsys.sigal.service.as.VnodbEntry;

public class VnodbDaoImpl implements VnodbDao {
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
     * @see com.initsys.sigal.service.as.dao.VnodbDao#queryDbByRef(String)
     */
    public VnodbEntry queryDbByRef(String ref) {
        return getTemplate()
                .queryForObject(
                        "select reference, max_calls from vno_information "
                                + "where reference = ?",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(VnodbEntry.class),
                        ref);
    }
}
