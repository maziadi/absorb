package com.initsys.sigal.service.as.dao;

import java.sql.Date;
import java.sql.Time;
import java.util.List;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.ParameterizedBeanPropertyRowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcTemplate;

import com.initsys.sigal.protocol.Sigal.EmdbDay;
import com.initsys.sigal.protocol.Sigal.EmdbQueryRequest;
import com.initsys.sigal.service.as.EmdbEntry;

public class EmdbDaoImpl implements EmdbDao {

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

    public List<EmdbEntry> query(EmdbQueryRequest emdbRequest, Time time,
            Date currentDay, int dayOfWeek, Date dayBefore) {
        if (getTemplate().queryForInt(
                "select count(*) from emergency_holiday where day = ?",
                currentDay) > 0) {
            dayOfWeek = EmdbDay.HOLIDAY.getNumber();
        } else if (getTemplate().queryForInt(
                "select count(*) from emergency_holiday where day = ?",
                dayBefore) > 0) {
            dayOfWeek = EmdbDay.AFTER_HOLIDAY.getNumber();
        }

        List<EmdbEntry> list = getTemplate()
                .query(
                        "select e.number, e.insee_code, e.translated_number, e.day_of_week, e.idx as `index` "
                                + "from emergency_translation e "
                                + "where e.number = ? "
                                + "  and e.insee_code = ? "
                                + "  and (day_of_week is null or day_of_week = ?) "
                                + "  and (e.begin_hour is null or e.begin_hour <= ?) "
                                + "  and (e.end_hour is null or ? <= e.end_hour) "
                                + "order by e.idx, e.day_of_week",
                        ParameterizedBeanPropertyRowMapper
                                .newInstance(EmdbEntry.class),
                        emdbRequest.getNumber(), emdbRequest.getInseeCode(),
                        dayOfWeek, time, time);
        return list;
    }
}
