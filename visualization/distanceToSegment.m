function d = distanceToSegment(px, py, ax, ay, bx, by)
%DISTANCETOSEGMENT Perpendicular distance from point (px,py) to segment AB.

    vx = bx - ax;
    vy = by - ay;
    wx = px - ax;
    wy = py - ay;

    segLenSq = vx^2 + vy^2;

    if segLenSq < 1e-12
        d = hypot(px - ax, py - ay);
        return;
    end

    t = (wx * vx + wy * vy) / segLenSq;
    t = max(0, min(1, t));

    projX = ax + t * vx;
    projY = ay + t * vy;

    d = hypot(px - projX, py - projY);
end