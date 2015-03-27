package org.angle3d.shadow;

/**
 * ShadowEdgeFiltering specifies how shadows are filtered
 */
enum EdgeFilteringMode
{
	/**
     * Shadows are not filtered. Nearest sample is used, causing in blocky
     * shadows.
     */
    Nearest;
    /**
     * Bilinear filtering is used.
     */
    Bilinear;
    /**
     * 3x3 percentage-closer filtering is used. Shadows will be smoother at the
     * cost of performance
     */
    PCF;
}