# Django core and 3rd party imports
from rest_framework.routers import DefaultRouter


class ContainerRouter(DefaultRouter):
    def register_router(self, router):
        self.registry.extend(router.registry)
