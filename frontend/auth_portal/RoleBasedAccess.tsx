import React from 'react';

export function withRole(Component: React.ComponentType, allowedRoles: string[]) {
  return function RoleWrapper(props: any) {
    // TODO: Get user role from context or JWT
    const userRole = 'admin'; // placeholder
    if (!allowedRoles.includes(userRole)) {
      return <div>Access Denied</div>;
    }
    return <Component {...props} />;
  };
}
