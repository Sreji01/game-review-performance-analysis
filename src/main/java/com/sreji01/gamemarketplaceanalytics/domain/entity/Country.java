package com.sreji01.gamemarketplaceanalytics.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;

import java.sql.Types;

@Entity
@Table(name = "countries", schema = "normalized")
public class Country {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Short id;

    @Column(nullable = false, unique = true, columnDefinition = "char(2)")
    @JdbcTypeCode(Types.CHAR)
    private String code;

    @Column(nullable = false, unique = true, length = 100)
    private String name;

    @Column(nullable = false, length = 30)
    private String region;
}
