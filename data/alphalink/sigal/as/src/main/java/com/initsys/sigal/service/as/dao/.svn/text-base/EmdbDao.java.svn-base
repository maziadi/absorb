package com.initsys.sigal.service.as.dao;

import java.sql.Date;
import java.sql.Time;
import java.util.List;

import com.initsys.sigal.protocol.Sigal.EmdbQueryRequest;
import com.initsys.sigal.service.as.EmdbEntry;

public interface EmdbDao {

    public List<EmdbEntry> query(EmdbQueryRequest emdbRequest, Time time,
            Date currentDay, int dayOfWeek, Date dayBefore);

}