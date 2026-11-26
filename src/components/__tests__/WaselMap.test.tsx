import { render, screen } from '@testing-library/react';
import { WaselMapCompact } from '../../components/WaselMap';

// Mock Leaflet to force fallback UI
jest.mock('leaflet', () => {
  return new Proxy({}, {
    get: () => jest.fn(),
  });
});

test('renders fallback SVG when Leaflet fails to load', async () => {
  render(<WaselMapCompact height={400} />);
  // The fallback UI shows a placeholder text
  const placeholder = await screen.findByText(/map unavailable/i);
  expect(placeholder).toBeInTheDocument();
});
