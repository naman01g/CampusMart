import { Routes, Route, Navigate, Outlet } from 'react-router-dom'
import { AuthProvider } from './features/auth/context/AuthContext'
import { Layout } from './shared/components/Layout'
import { HomePage } from './features/home/pages/HomePage'
import { ListingsPage } from './features/listings/pages/ListingsPage'
import { ListingDetailPage } from './features/listings/pages/ListingDetailPage'
import { CreateListingPage } from './features/listings/pages/CreateListingPage'
import { EditListingPage } from './features/listings/pages/EditListingPage'
import { ChatListPage } from './features/chat/pages/ChatListPage'
import { ChatPage } from './features/chat/pages/ChatPage'
import { NotificationsPage } from './features/notifications/pages/NotificationsPage'
import { ProfilePage } from './features/user/pages/ProfilePage'
import { MyListingsPage } from './features/user/pages/MyListingsPage'
import { FavoritesPage } from './features/user/pages/FavoritesPage'
import { LoginPage } from './features/auth/pages/LoginPage'
import { RegisterPage } from './features/auth/pages/RegisterPage'
import { ForgotPasswordPage } from './features/auth/pages/ForgotPasswordPage'
import { EmailVerificationPage } from './features/auth/pages/EmailVerificationPage'
import { ProtectedRoute, AdminRoute } from './shared/components/ProtectedRoute'
import { AdminLayout } from './features/admin/components/AdminLayout'
import { AdminDashboardPage } from './features/admin/pages/AdminDashboardPage'
import { AdminListingsPage } from './features/admin/pages/AdminListingsPage'
import { AdminUsersPage } from './features/admin/pages/AdminUsersPage'
import { AdminReportsPage } from './features/admin/pages/AdminReportsPage'
import { useAuth } from './features/auth/context/AuthContext'

function VerifiedRoute() {
  const { user, loading } = useAuth();
  
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-12 h-12 border-4 border-[var(--color-border)] border-t-[var(--color-ochre)] rounded-full animate-spin" />
      </div>
    );
  }
  
  if (!user) {
    return <Navigate to="/login" replace />;
  }
  
  if (!user.isVerified) {
    return <Navigate to="/verify-email" replace />;
  }
  
  return <Outlet />;
}

function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<HomePage />} />
          <Route path="listings" element={<ListingsPage />} />
          <Route path="listings/:id" element={<ListingDetailPage />} />
          <Route path="chat" element={<ChatListPage />} />
          <Route path="chat/:chatId" element={<ChatPage />} />
          <Route path="notifications" element={<NotificationsPage />} />
          
          <Route element={<ProtectedRoute />}>
            <Route element={<VerifiedRoute />}>
              <Route path="sell" element={<CreateListingPage />} />
              <Route path="listings/:id/edit" element={<EditListingPage />} />
              <Route path="profile" element={<ProfilePage />} />
              <Route path="my-listings" element={<MyListingsPage />} />
              <Route path="favorites" element={<FavoritesPage />} />
            </Route>
            
            <Route path="login" element={<LoginPage />} />
            <Route path="register" element={<RegisterPage />} />
            <Route path="forgot-password" element={<ForgotPasswordPage />} />
            <Route path="verify-email" element={<EmailVerificationPage />} />
          </Route>
        </Route>
        
        <Route path="/admin/*" element={<AdminLayout />}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route element={<AdminRoute />}>
            <Route path="dashboard" element={<AdminDashboardPage />} />
            <Route path="listings" element={<AdminListingsPage />} />
            <Route path="users" element={<AdminUsersPage />} />
            <Route path="reports" element={<AdminReportsPage />} />
          </Route>
        </Route>
        
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  )
}

export default App