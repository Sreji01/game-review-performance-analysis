package com.sreji01.gamemarketplaceanalytics.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinColumns;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(
        name = "reviews",
        schema = "normalized",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "game_id", "platform_id"})
)
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(optional = false)
    @JoinColumns({
            @JoinColumn(name = "game_id", referencedColumnName = "game_id", nullable = false),
            @JoinColumn(name = "platform_id", referencedColumnName = "platform_id", nullable = false)
    })
    private GamePlatform gamePlatform;

    @Column(nullable = false)
    private Short rating;

    @Column(name = "review_title", length = 150)
    private String reviewTitle;

    @Column(name = "review_text", nullable = false, columnDefinition = "text")
    private String reviewText;

    @Column(name = "playtime_hours", precision = 10, scale = 1)
    private BigDecimal playtimeHours;

    @Column(name = "is_recommended", nullable = false)
    private Boolean recommended;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;
}
