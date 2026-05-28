package com.sreji01.gamemarketplaceanalytics.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
        name = "publishers",
        schema = "normalized",
        uniqueConstraints = @UniqueConstraint(columnNames = {"name", "country_id"})
)
public class Publisher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @ManyToOne
    @JoinColumn(name = "country_id")
    private Country country;

    @Column(name = "founded_year")
    private Short foundedYear;

    @Column(name = "website_url", columnDefinition = "text")
    private String websiteUrl;
}
