// Real-user Core Web Vitals reporting (npm i web-vitals).
// Sends no personal data: route pattern only (no IDs or query string), no user ID. The browser may
// attach same-origin cookies to the beacon, so the endpoint must not read the session or store IPs.
// Call reportWebVitals() once on the client, e.g. in a root client component or app entry.
import { onCLS, onFCP, onINP, onLCP, onTTFB, type MetricWithAttribution } from 'web-vitals/attribution';

const ENDPOINT = '/api/vitals'; // your own, rate-limited endpoint

// "/bookings/8f3a2c/edit?x=1" -> "/bookings/:id/edit"
function routePattern(pathname: string): string {
  return pathname
    .split('/')
    .map((part) => (/^\d+$|^[0-9a-f-]{8,}$/i.test(part) ? ':id' : part))
    .join('/');
}

function target(metric: MetricWithAttribution): string | undefined {
  const a = metric.attribution as Record<string, unknown>;
  const value = a.target ?? a.interactionTarget ?? a.largestShiftTarget;
  return typeof value === 'string' ? value.slice(0, 200) : undefined;
}

function send(metric: MetricWithAttribution): void {
  const body = JSON.stringify({
    name: metric.name,
    value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
    rating: metric.rating,
    route: routePattern(location.pathname),
    target: target(metric),
    nav: metric.navigationType,
    mobile: matchMedia('(max-width: 768px)').matches,
  });
  if (!navigator.sendBeacon?.(ENDPOINT, body)) {
    fetch(ENDPOINT, { method: 'POST', body, keepalive: true, credentials: 'omit' }).catch(() => {});
  }
}

export function reportWebVitals(): void {
  onLCP(send);
  onINP(send);
  onCLS(send);
  onFCP(send);
  onTTFB(send);
}
