package org.angle3d.shadow;

/**
 * ...
 * @author 
 */
enum EdgeFilteringMode
{
 /**
     * Shadows are not filtered. Nearest sample is used, causing in blocky
     * shadows.
     */
    Nearest;
    /**
     * Bilinear filtering is used. Has the potential of being hardware
     * accelerated on some GPUs
     */
    Bilinear;
    /**
     * Dither-based sampling is used, very cheap but can look bad at low
     * resolutions.
     */
    Dither;
    /**
     * 4x4 percentage-closer filtering is used. Shadows will be smoother at the
     * cost of performance
     */
    PCF4;
    /**
     * 8x8 percentage-closer filtering is used. Shadows will be smoother at the
     * cost of performance
     */
    PCFPOISSON;
    /**
     * 8x8 percentage-closer filtering is used. Shadows will be smoother at the
     * cost of performance
     */
    PCF8;
}