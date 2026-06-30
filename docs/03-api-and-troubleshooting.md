# API Quirks and Troubleshooting

## Team Invites
- The correct CTFd API endpoint for generating a team invite link is `POST /api/v1/teams/me/members` with an empty JSON body `{}`.
- Do NOT use `/api/v1/teams/me/tokens` (returns 404).
- Only Team Captains can generate invite codes (returns 403 otherwise).

## Email Resend
- In `confirm.html`, the resend confirmation button triggers `POST /confirm`. 
- Even if the response is 200 OK, emails might land in the Spam/Junk folder (especially for strict domains like `.edu.vn`).

## Deployment Scripts
When updating theme templates, use SCP to transfer files to the GCP VM and then copy them to the Docker volume path.
Example:
```bash
gcloud compute scp "local/path/template.html" ubuntu@ctf-vm1-web:/home/ubuntu/ --tunnel-through-iap
gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap --command="sudo cp /home/ubuntu/template.html /opt/ctfd/themes/ctfd-theme-neubrutalism/templates/template.html && sudo docker exec ctfd_cache_1 redis-cli FLUSHALL"
```
**Important:** Always flush the Redis cache (`FLUSHALL`) after modifying HTML templates so CTFd picks up the changes immediately.
