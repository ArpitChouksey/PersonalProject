import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

def hello(request, name):
    return JsonResponse({
        "message": f"Hello {name}"
    })

@csrf_exempt
def create_user(request):
    if request.method != 'POST':
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        body = json.loads(request.body)
        name = body.get("name")
        email = body.get("email")

        if not name or not email:
            return JsonResponse({"error": "name and email required"}, status=400)

        # DB logic comes later
        return JsonResponse({
            "message": "User received",
            "name": name,
            "email": email
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

