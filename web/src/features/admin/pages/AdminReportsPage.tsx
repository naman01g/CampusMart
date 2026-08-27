import { useState, useEffect } from 'react';
import { Card, CardContent, Badge, Button } from '@shared/components/ui';
import { Report, ReportStatus, ReportTargetType, toDate } from '@shared/types';
import { getFirebaseDb } from '@shared/utils/firebase';
import { collection, query, where, orderBy, getDocs, updateDoc, doc, limit, startAfter, DocumentSnapshot, getDoc } from 'firebase/firestore';
import { formatDistanceToNow } from 'date-fns';

export function AdminReportsPage() {
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'ALL'>('ALL');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    fetchReports(true);
  }, [statusFilter]);

  const fetchReports = async (reset = false) => {
    if (reset) {
      setLoading(true);
      setLastDoc(null);
      setReports([]);
      setHasMore(true);
    } else {
      setLoadingMore(true);
    }

    try {
      const db = getFirebaseDb();
      let q = query(
        collection(db, 'reports'),
        orderBy('createdAt', 'desc'),
        limit(20)
      );

      if (statusFilter !== 'ALL') {
        q = query(q, where('status', '==', statusFilter));
      }

      if (lastDoc) {
        q = query(q, startAfter(lastDoc));
      }

      const snapshot = await getDocs(q);
      const newReports = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Report));
      
      if (reset) {
        setReports(newReports);
      } else {
        setReports(prev => [...prev, ...newReports]);
      }
      
      setLastDoc(snapshot.docs[snapshot.docs.length - 1] || null);
      setHasMore(newReports.length === 20);
    } catch (error) {
      console.error('Error fetching reports:', error);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const handleStatusChange = async (reportId: string, newStatus: ReportStatus) => {
    try {
      const db = getFirebaseDb();
      await updateDoc(doc(db, 'reports', reportId), { status: newStatus, updatedAt: new Date() });
      setReports(prev => prev.map(r => r.id === reportId ? { ...r, status: newStatus } : r));
    } catch (error) {
      console.error('Error updating status:', error);
    }
  };

  const getTargetInfo = async (report: Report) => {
    try {
      const db = getFirebaseDb();
      const targetRef = doc(db, report.targetType === 'product' ? 'products' : 'users', report.targetId);
      const targetSnap = await getDoc(targetRef);
      return targetSnap.exists() ? targetSnap.data() : null;
    } catch {
      return null;
    }
  };

  const statusOptions = ['ALL', 'pending', 'reviewed', 'resolved', 'dismissed'] as const;

  if (loading) {
    return (
      <div>
        <h1 className="text-h2 mb-24" style={{ color: 'var(--color-charcoal)' }}>Reports</h1>
        <div className="space-y-12">
          {[...Array(4)].map((_, i) => (
            <Card key={i} padding="md">
              <div className="animate-pulse">
                <div className="h-6 bg-[var(--color-border)] rounded w-1/4 mb-8" />
                <div className="h-4 bg-[var(--color-border)] rounded w-1/2" />
              </div>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-24">
        <h1 className="text-h2" style={{ color: 'var(--color-charcoal)' }}>Reports</h1>
        <div className="flex gap-8">
          {statusOptions.map(status => (
            <button
              key={status}
              onClick={() => setStatusFilter(status as ReportStatus | 'ALL')}
              className={`px-12 py-8 text-body-sm font-medium rounded-lg transition-colors ${
                statusFilter === status
                  ? 'bg-[var(--color-ochre)] text-white'
                  : 'bg-[var(--color-surface)] border border-[var(--color-border)] hover:border-[var(--color-ochre)]'
              }`}
            >
              {status.charAt(0).toUpperCase() + status.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {reports.length === 0 ? (
        <Card padding="lg" className="text-center py-24">
          <div className="text-6xl mb-12">📋</div>
          <h3 className="text-h3 mb-8" style={{ color: 'var(--color-charcoal)' }}>No reports found</h3>
          <p className="text-body text-[var(--color-secondary-text)]">
            {statusFilter !== 'ALL' ? `No ${statusFilter} reports` : 'No reports in the system'}
          </p>
        </Card>
      ) : (
        <>
          <div className="space-y-12">
            {reports.map(report => (
              <Card key={report.id} padding="md">
                <div className="flex items-start justify-between gap-16">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-12 mb-4 flex-wrap">
                      <Badge type={report.targetType === 'product' ? 'SELL' : 'ACTIVE'}>
                        {report.targetType}
                      </Badge>
                      <Badge type={report.status === 'pending' ? 'ACTIVE' : report.status === 'resolved' ? 'ACTIVE' : 'REMOVED'}>
                        {report.status.charAt(0).toUpperCase() + report.status.slice(1)}
                      </Badge>
                      <span className="text-caption text-[var(--color-secondary-text)]">
                        {formatDistanceToNow(toDate(report.createdAt), { addSuffix: true })}
                      </span>
                    </div>
                    <h3 className="text-body font-medium mb-4" style={{ color: 'var(--color-charcoal)' }}>
                      {report.reason}
                    </h3>
                    {report.description && (
                      <p className="text-body-sm text-[var(--color-secondary-text)] mb-4">
                        {report.description}
                      </p>
                    )}
                    <p className="text-caption text-[var(--color-secondary-text)]">
                      Reported by: {report.reportedBy.substring(0, 8)}... • Target: {report.targetId.substring(0, 8)}...
                    </p>
                  </div>
                  <div className="flex items-center gap-8">
                    <select
                      value={report.status}
                      onChange={(e) => handleStatusChange(report.id, e.target.value as ReportStatus)}
                      className="input w-auto text-body-sm"
                    >
                      <option value="pending">Pending</option>
                      <option value="reviewed">Reviewed</option>
                      <option value="resolved">Resolved</option>
                      <option value="dismissed">Dismissed</option>
                    </select>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setExpandedId(expandedId === report.id ? null : report.id)}
                    >
                      {expandedId === report.id ? 'Hide' : 'Details'}
                    </Button>
                  </div>
                </div>
                
                {expandedId === report.id && (
                  <div className="mt-16 pt-16 border-t border-[var(--color-border)]">
                    <h4 className="text-body font-medium mb-8" style={{ color: 'var(--color-charcoal)' }}>Details</h4>
                    <div className="grid sm:grid-cols-2 gap-16 text-body-sm">
                      <div>
                        <p className="text-[var(--color-secondary-text)]">Report ID</p>
                        <p style={{ color: 'var(--color-primary-text)' }}>{report.id}</p>
                      </div>
                      <div>
                        <p className="text-[var(--color-secondary-text)]">Target Type</p>
                        <p style={{ color: 'var(--color-primary-text)' }}>{report.targetType}</p>
                      </div>
                      <div>
                        <p className="text-[var(--color-secondary-text)]">Target ID</p>
                        <p style={{ color: 'var(--color-primary-text)' }}>{report.targetId}</p>
                      </div>
                      <div>
                        <p className="text-[var(--color-secondary-text)]">Reporter ID</p>
                        <p style={{ color: 'var(--color-primary-text)' }}>{report.reportedBy}</p>
                      </div>
                      <div>
                        <p className="text-[var(--color-secondary-text)]">Reason</p>
                        <p style={{ color: 'var(--color-primary-text)' }}>{report.reason}</p>
                      </div>
                      <div>
                        <p className="text-[var(--color-secondary-text)]">Created</p>
                        <p style={{ color: 'var(--color-primary-text)' }}>
                          {toDate(report.createdAt).toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>
                )}
              </Card>
            ))}
          </div>

          {hasMore && (
            <div className="text-center mt-24">
              <Button variant="outline" onClick={() => fetchReports(false)} loading={loadingMore}>
                Load More
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}