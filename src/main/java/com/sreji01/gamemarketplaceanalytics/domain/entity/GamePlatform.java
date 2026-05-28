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

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(
        name = "game_platforms",
        schema = "normalized",
        uniqueConstraints = @UniqueConstraint(columnNames = {"game_id", "platform_id"})
)
public class GamePlatform {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "game_id", nullable = false)
    private Game game;

    @ManyToOne(optional = false)
    @JoinColumn(name = "platform_id", nullable = false)
    private Platform platform;

    @Column(name = "release_date", nullable = false)
    private LocalDate releaseDate;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
}
