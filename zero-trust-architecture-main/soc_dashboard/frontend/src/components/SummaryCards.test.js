import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import SummaryCards from './SummaryCards';

describe('SummaryCards', () => {
  it('renders alert, compliance, and risk metrics', () => {
    const metrics = { alerts: 10, compliance: 95, risk: 7.5 };
    render(<SummaryCards metrics={metrics} />);
    expect(screen.getByText('Total Alerts')).toBeInTheDocument();
    expect(screen.getByText('Compliance Rate')).toBeInTheDocument();
    expect(screen.getByText('Risk Score')).toBeInTheDocument();
    expect(screen.getByText('10')).toBeInTheDocument();
    expect(screen.getByText('95%')).toBeInTheDocument();
    expect(screen.getByText('7.5')).toBeInTheDocument();
  });
});
